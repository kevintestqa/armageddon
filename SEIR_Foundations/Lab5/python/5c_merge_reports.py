#!/usr/bin/env python3
"""
Lab 5A-Plus-Plus: Local LLM merges multiple security tool outputs into one analyst report.

Upgrades:
1) Chunking + hierarchical merge (map/reduce) for large finding sets
2) Cross-tool dedupe (fuzzy fingerprinting)
3) "No exploit content" filter: strips payload-like strings, code blocks, obvious exploit markers

Rules enforced:
- No invented severities, CVEs, or overall risk score.
- Severity must be preserved from tool output; missing => UNSPECIFIED.
- Sanitizes secrets + PHI-ish patterns before sending to local LLM.
- Supports mode: tokyo | ny | both (reads inputs/<mode>/).
"""

import argparse
import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
import urllib.request

SEV_ORDER = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO", "UNSPECIFIED"]

# ----------------------------
# Sanitization (secrets + PHI-ish)
# ----------------------------
SECRET_PATTERNS = [
    (re.compile(r"\bAKIA[0-9A-Z]{16}\b"), "[REDACTED_AWS_ACCESS_KEY_ID]"),
    (re.compile(r"\bASIA[0-9A-Z]{16}\b"), "[REDACTED_AWS_ACCESS_KEY_ID]"),
    (re.compile(r"(?i)\baws_secret_access_key\b\s*[:=]\s*['\"]?([A-Za-z0-9/+=]{20,})['\"]?"), "aws_secret_access_key=[REDACTED]"),
    (re.compile(r"(?i)\b(api[_-]?key|secret|token|password|passwd|pwd)\b\s*[:=]\s*['\"]?([^'\"\s]{6,})['\"]?"), r"\1=[REDACTED]"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----", re.DOTALL), "[REDACTED_PRIVATE_KEY]"),
]

PHI_PATTERNS = [
    (re.compile(r"(?i)\b(patient\s*name|dob|date\s*of\s*birth|ssn|social\s*security|medical\s*record|mrn|diagnosis)\b\s*[:=]\s*.*"), "[REDACTED_PHI_LINE]"),
    (re.compile(r"\b\d{3}-\d{2}-\d{4}\b"), "[REDACTED_SSN]"),
    (re.compile(r"\b\d{2}/\d{2}/\d{4}\b"), "[REDACTED_DATE]"),
    (re.compile(r"\b\d{4}-\d{2}-\d{2}\b"), "[REDACTED_DATE]"),
]

# ----------------------------
# "No exploit content" filter
# ----------------------------
EXPLOIT_PATTERNS = [
    # common payload signatures / meta
    (re.compile(r"(?i)\b(union\s+select|or\s+1=1|sleep\(\d+\)|benchmark\(|xp_cmdshell)\b"), "[REDACTED_PAYLOAD_SNIPPET]"),
    (re.compile(r"(?i)<script\b.*?>.*?</script>"), "[REDACTED_SCRIPT_BLOCK]"),
    (re.compile(r"(?i)\b(jndi:ldap|jndi:rmi)\b"), "[REDACTED_JNDI]"),
    (re.compile(r"(?i)\b(\.\./|\.\.\\){2,}"), "[REDACTED_TRAVERSAL]"),
    (re.compile(r"(?i)\b(curl\s+http|wget\s+http|powershell\s+-enc|nc\s+-e)\b"), "[REDACTED_CMD_SNIPPET]"),
    # code fences: keep but remove contents
    (re.compile(r"```.*?```", re.DOTALL), "```[REDACTED_CODE_BLOCK]```"),
]

def sanitize_text(s: str) -> str:
    if not s:
        return s
    out = s
    for pat, repl in SECRET_PATTERNS:
        out = pat.sub(repl, out)
    for pat, repl in PHI_PATTERNS:
        out = pat.sub(repl, out)
    for pat, repl in EXPLOIT_PATTERNS:
        out = pat.sub(repl, out)
    return out

def normalize_sev(sev: Optional[str]) -> str:
    if not sev:
        return "UNSPECIFIED"
    s = str(sev).strip().upper()
    mapping = {
        "CRIT": "CRITICAL",
        "SEVERE": "HIGH",
        "MODERATE": "MEDIUM",
        "INFORMATIONAL": "INFO",
        "INFORMATION": "INFO",
    }
    s = mapping.get(s, s)
    return s if s in SEV_ORDER else "UNSPECIFIED"

def stable_id(*parts: str) -> str:
    raw = "||".join([p or "" for p in parts]).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()[:16]

def fingerprint_text(s: str) -> str:
    """
    Fuzzy fingerprint key to dedupe across tools.
    - lowercases
    - strips digits and noise
    - keeps words
    """
    s = (s or "").lower()
    s = re.sub(r"https?://\S+", " ", s)          # drop urls
    s = re.sub(r"\b\d+\b", " ", s)               # drop pure digits
    s = re.sub(r"[^a-z0-9\s]", " ", s)           # strip punctuation
    s = re.sub(r"\s+", " ", s).strip()
    # keep first N tokens as a stable-ish signature
    toks = s.split()[:24]
    return " ".join(toks)

@dataclass
class Finding:
    source: str
    tool: str
    severity: str
    title: str
    description: str = ""
    resource: str = ""
    cve: str = ""
    category: str = ""         # OWASP / IaC / Cloud / Dependencies / Network / AI / Unknown
    owasp_hint: str = ""
    raw_ref: str = ""
    finding_id: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "finding_id": self.finding_id,
            "source": self.source,
            "tool": self.tool,
            "severity": self.severity,
            "title": self.title,
            "description": self.description,
            "resource": self.resource,
            "cve": self.cve,
            "category": self.category,
            "owasp_hint": self.owasp_hint,
            "raw_ref": self.raw_ref,
        }

# ----------------------------
# Tool-specific parsers (same core as before, but enforced sanitize)
# ----------------------------

def owasp_hint_from_text(text: str) -> str:
    t = (text or "").lower()
    if "access control" in t or "unauthorized" in t or "forbidden" in t:
        return "A01"
    if "crypto" in t or "tls" in t or "certificate" in t:
        return "A02"
    if "injection" in t or "sql" in t or "xss" in t:
        return "A03"
    if "misconfig" in t or "header" in t or "directory listing" in t:
        return "A05"
    if "outdated" in t or "cve" in t or "vulnerable component" in t:
        return "A06"
    if "authentication" in t or "session" in t or "jwt" in t:
        return "A07"
    if "integrity" in t or "signature" in t or "supply chain" in t:
        return "A08"
    if "logging" in t or "monitoring" in t or "alert" in t:
        return "A09"
    if "ssrf" in t:
        return "A10"
    return ""

def load_json(path: Path) -> Optional[Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None

def choose_parser(filename: str):
    n = filename.lower()
    if "zap" in n:
        return "zap"
    if "trivy" in n:
        return "trivy"
    if "grype" in n:
        return "grype"
    if "checkov" in n:
        return "checkov"
    if "tfsec" in n:
        return "tfsec"
    if "prowler" in n:
        return "prowler"
    if n.endswith("aws_evidence.json"):
        return "aws_evidence"
    if n.endswith("gcp_evidence.json"):
        return "gcp_evidence"
    return "generic"

def parse_zap(obj: Any, source: str) -> List[Finding]:
    findings: List[Finding] = []
    try:
        sites = obj.get("site") if isinstance(obj, dict) else None
        if isinstance(sites, dict):
            sites = [sites]
        if not isinstance(sites, list):
            return findings

        for site in sites:
            alerts = site.get("alerts", []) or []
            for a in alerts:
                risk = a.get("risk") or a.get("riskdesc") or a.get("riskDesc") or ""
                sev = normalize_sev(re.split(r"\s|\(", str(risk))[0])
                title = a.get("alert") or a.get("name") or "ZAP Alert"
                desc = a.get("desc") or a.get("description") or ""
                sol = a.get("solution") or ""
                ref = a.get("reference") or ""
                resource = site.get("@name") or site.get("name") or ""

                full = sanitize_text((str(desc) + "\nSolution: " + str(sol) + "\nRef: " + str(ref))[:4000])
                f = Finding(
                    source=source,
                    tool="ZAP",
                    severity=sev,
                    title=sanitize_text(str(title)[:200]),
                    description=full[:2000],
                    resource=sanitize_text(str(resource)[:500]),
                    category="OWASP",
                )
                f.owasp_hint = owasp_hint_from_text(f.title + " " + f.description)
                f.finding_id = stable_id(f.tool, f.severity, f.title, f.resource)
                findings.append(f)
    except Exception:
        return findings
    return findings

def parse_trivy(obj: Any, source: str) -> List[Finding]:
    findings: List[Finding] = []
    if not isinstance(obj, dict):
        return findings
    results = obj.get("Results", []) or []
    if not isinstance(results, list):
        return findings

    for r in results:
        target = r.get("Target") or ""
        vulns = r.get("Vulnerabilities", []) or []
        if not isinstance(vulns, list):
            continue
        for v in vulns:
            sev = normalize_sev(v.get("Severity"))
            vid = v.get("VulnerabilityID") or ""
            pkg = v.get("PkgName") or ""
            title = f"{vid} in {pkg}".strip() if (vid or pkg) else (v.get("Title") or "Trivy Finding")
            desc = v.get("Description") or v.get("Title") or ""
            f = Finding(
                source=source,
                tool="Trivy",
                severity=sev,
                title=sanitize_text(str(title)[:200]),
                description=sanitize_text(str(desc)[:2000]),
                resource=sanitize_text(str(target)[:500]),
                cve=str(vid),
                category="Dependencies",
            )
            f.finding_id = stable_id(f.tool, f.severity, f.title, f.resource, f.cve)
            findings.append(f)
    return findings

def parse_grype(obj: Any, source: str) -> List[Finding]:
    findings: List[Finding] = []
    if not isinstance(obj, dict):
        return findings
    matches = obj.get("matches", []) or []
    if not isinstance(matches, list):
        return findings
    for m in matches:
        v = m.get("vulnerability", {}) or {}
        a = m.get("artifact", {}) or {}
        vid = v.get("id") or ""
        sev = normalize_sev(v.get("severity"))
        name = a.get("name") or ""
        ver = a.get("version") or ""
        title = f"{vid} in {name} {ver}".strip()
        desc = v.get("description") or ""
        f = Finding(
            source=source,
            tool="Grype",
            severity=sev,
            title=sanitize_text(str(title)[:200]),
            description=sanitize_text(str(desc)[:2000]),
            resource=sanitize_text(f"{name}:{ver}"[:500]),
            cve=str(vid),
            category="Dependencies",
        )
        f.finding_id = stable_id(f.tool, f.severity, f.title, f.resource, f.cve)
        findings.append(f)
    return findings

def parse_checkov(obj: Any, source: str) -> List[Finding]:
    findings: List[Finding] = []
    if not isinstance(obj, dict):
        return findings
    results = obj.get("results", {}) or {}
    failed = results.get("failed_checks", []) or results.get("failed", []) or []
    if not isinstance(failed, list):
        return findings
    for c in failed:
        sev = normalize_sev(c.get("severity"))
        cid = c.get("check_id") or ""
        name = c.get("check_name") or "Checkov finding"
        res = c.get("resource") or ""
        file_path = c.get("file_path") or ""
        guideline = c.get("guideline") or ""
        desc = f"{name}\nGuideline: {guideline}".strip()
        f = Finding(
            source=source,
            tool="Checkov",
            severity=sev,
            title=sanitize_text(f"{cid} {name}".strip()[:200]),
            description=sanitize_text(desc[:2000]),
            resource=sanitize_text(str(res or file_path)[:500]),
            category="IaC",
            raw_ref=sanitize_text(str(file_path)[:500]),
        )
        f.finding_id = stable_id(f.tool, f.severity, f.title, f.resource, f.raw_ref)
        findings.append(f)
    return findings

def parse_tfsec(obj: Any, source: str) -> List[Finding]:
    findings: List[Finding] = []
    if not isinstance(obj, dict):
        return findings
    results = obj.get("results", []) or []
    if not isinstance(results, list):
        return findings
    for r in results:
        sev = normalize_sev(r.get("severity"))
        rid = r.get("rule_id") or r.get("long_id") or ""
        desc = r.get("description") or ""
        impact = r.get("impact") or ""
        resolution = r.get("resolution") or ""
        loc = r.get("location", {}) or {}
        filename = loc.get("filename") or ""
        line = loc.get("start_line") or ""
        raw_ref = f"{filename}:{line}".strip(":")
        title = rid if rid else (r.get("summary") or "tfsec finding")
        full = f"{desc}\nImpact: {impact}\nResolution: {resolution}"
        f = Finding(
            source=source,
            tool="tfsec",
            severity=sev,
            title=sanitize_text(str(title)[:200]),
            description=sanitize_text(full[:2000]),
            resource=sanitize_text(str(filename)[:500]),
            category="IaC",
            raw_ref=sanitize_text(raw_ref[:500]),
        )
        f.finding_id = stable_id(f.tool, f.severity, f.title, f.resource, f.raw_ref)
        findings.append(f)
    return findings

def parse_prowler(obj: Any, source: str) -> List[Finding]:
    findings: List[Finding] = []
    items: List[Dict[str, Any]] = []
    if isinstance(obj, list):
        items = obj
    elif isinstance(obj, dict):
        items = obj.get("findings") or obj.get("Results") or obj.get("results") or obj.get("Checks") or []
        if isinstance(items, dict):
            items = list(items.values())
        if not isinstance(items, list):
            items = []

    for it in items:
        if not isinstance(it, dict):
            continue
        sev = normalize_sev(it.get("Severity") or it.get("severity"))
        title = it.get("Finding") or it.get("CheckTitle") or it.get("CheckID") or "Prowler finding"
        res = it.get("ResourceId") or it.get("ResourceArn") or ""
        desc = it.get("Description") or it.get("description") or it.get("Remediation") or ""
        f = Finding(
            source=source,
            tool="Prowler",
            severity=sev,
            title=sanitize_text(str(title)[:200]),
            description=sanitize_text(str(desc)[:2000]),
            resource=sanitize_text(str(res)[:500]),
            category="Cloud",
        )
        f.finding_id = stable_id(f.tool, f.severity, f.title, f.resource)
        findings.append(f)
    return findings

def parse_evidence_json(obj: Any, source: str, tool_name: str) -> List[Finding]:
    findings: List[Finding] = []
    if not isinstance(obj, dict):
        return findings
    checks = obj.get("checks", {})
    if not isinstance(checks, dict):
        return findings
    for k, v in checks.items():
        title = f"{tool_name} evidence: {k}"
        desc = v if isinstance(v, str) else json.dumps(v)[:4000]
        f = Finding(
            source=source,
            tool=tool_name,
            severity="UNSPECIFIED",
            title=sanitize_text(title[:200]),
            description=sanitize_text(desc[:2000]),
            resource="",
            category="Cloud",
        )
        f.finding_id = stable_id(f.tool, f.title)
        findings.append(f)
    return findings

def parse_generic(obj: Any, source: str) -> List[Finding]:
    findings: List[Finding] = []

    def walk(x):
        if isinstance(x, dict):
            yield x
            for v in x.values():
                yield from walk(v)
        elif isinstance(x, list):
            for i in x:
                yield from walk(i)

    for d in walk(obj):
        if not isinstance(d, dict):
            continue
        keys = {k.lower() for k in d.keys()}
        if any(k in keys for k in ["severity", "level", "risk", "priority"]) and any(k in keys for k in ["title", "name", "check", "rule", "id"]):
            title = d.get("title") or d.get("name") or d.get("check") or d.get("rule") or d.get("id") or "Generic finding"
            sev = normalize_sev(d.get("severity") or d.get("level") or d.get("risk") or d.get("priority"))
            desc = d.get("description") or d.get("message") or d.get("details") or ""
            res = d.get("resource") or d.get("file") or d.get("path") or d.get("target") or ""
            f = Finding(
                source=source,
                tool="Generic",
                severity=sev,
                title=sanitize_text(str(title)[:200]),
                description=sanitize_text(str(desc)[:2000]),
                resource=sanitize_text(str(res)[:500]),
                category="Unknown",
            )
            f.finding_id = stable_id(f.tool, f.severity, f.title, f.resource)
            findings.append(f)

    return findings

def parse_file(path: Path) -> List[Finding]:
    obj = load_json(path)
    if obj is None:
        return []
    kind = choose_parser(path.name)
    source = path.stem
    if kind == "zap":
        return parse_zap(obj, source)
    if kind == "trivy":
        return parse_trivy(obj, source)
    if kind == "grype":
        return parse_grype(obj, source)
    if kind == "checkov":
        return parse_checkov(obj, source)
    if kind == "tfsec":
        return parse_tfsec(obj, source)
    if kind == "prowler":
        return parse_prowler(obj, source)
    if kind == "aws_evidence":
        return parse_evidence_json(obj, source, "AWS_Evidence")
    if kind == "gcp_evidence":
        return parse_evidence_json(obj, source, "GCP_Evidence")
    return parse_generic(obj, source)

def classify_defaults(findings: List[Finding]) -> None:
    for f in findings:
        if not f.category or f.category == "Unknown":
            if f.tool in ("Trivy", "Grype"):
                f.category = "Dependencies"
            elif f.tool in ("Checkov", "tfsec"):
                f.category = "IaC"
            elif f.tool in ("Prowler", "AWS_Evidence", "GCP_Evidence"):
                f.category = "Cloud"
            elif f.tool == "ZAP":
                f.category = "OWASP"
            else:
                f.category = "Unknown"

        if f.tool == "ZAP" and not f.owasp_hint:
            f.owasp_hint = owasp_hint_from_text(f.title + " " + f.description)

# ----------------------------
# Cross-tool dedupe (fuzzy)
# ----------------------------
def cross_tool_dedupe(findings: List[Finding]) -> Tuple[List[Finding], List[Tuple[str, str]]]:
    """
    Dedupe across tools by fuzzy fingerprint:
    - key includes normalized title signature + resource signature (+ cve if present)
    - keeps the highest severity among duplicates but DOES NOT change per-record severity;
      instead we keep one representative record and list duplicates in a separate map.
    Returns:
      - deduped list
      - list of (kept_finding_id, dropped_finding_id) duplicate pairs
    """
    # severity rank for choosing representative
    rank = {s: i for i, s in enumerate(SEV_ORDER)}  # lower is worse? We'll invert.
    def sev_score(s: str) -> int:
        # CRITICAL should win
        return (len(SEV_ORDER) - 1) - rank.get(s, rank["UNSPECIFIED"])

    buckets: Dict[str, List[Finding]] = {}
    for f in findings:
        sig_title = fingerprint_text(f.title)
        sig_res = fingerprint_text(f.resource)
        sig_cve = (f.cve or "").lower().strip()
        key = f"{sig_title}||{sig_res}||{sig_cve}"
        buckets.setdefault(key, []).append(f)

    kept: List[Finding] = []
    dup_pairs: List[Tuple[str, str]] = []

    for _, group in buckets.items():
        if len(group) == 1:
            kept.append(group[0])
            continue
        # choose representative: highest severity, then most descriptive
        group_sorted = sorted(
            group,
            key=lambda x: (sev_score(x.severity), len(x.description or ""), len(x.resource or "")),
            reverse=True
        )
        rep = group_sorted[0]
        kept.append(rep)
        for g in group_sorted[1:]:
            dup_pairs.append((rep.finding_id, g.finding_id))

    return kept, dup_pairs

# ----------------------------
# Local LLM call (Ollama)
# ----------------------------
def call_ollama(prompt: str, model: str, url: str) -> str:
    payload = json.dumps({"model": model, "prompt": prompt, "stream": False}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=240) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return data.get("response", "").strip()

# ----------------------------
# Chunking + hierarchical merge
# ----------------------------
def chunk_findings(findings: List[Finding], chunk_size: int) -> List[List[Finding]]:
    return [findings[i:i+chunk_size] for i in range(0, len(findings), chunk_size)]

def build_map_prompt(findings: List[Finding], mode: str, chunk_index: int, total_chunks: int) -> str:
    items = []
    for f in findings:
        items.append({
            "finding_id": f.finding_id,
            "tool": f.tool,
            "source": f.source,
            "severity": f.severity,
            "category": f.category,
            "owasp_hint": f.owasp_hint,
            "title": f.title,
            "resource": f.resource,
            "description": f.description,
        })

    rules = f"""
You are a security report CHUNK SUMMARIZER running OFFLINE on a local machine.

Hard rules:
- Do NOT invent or change severity levels.
- Do NOT generate any overall risk score.
- Do NOT invent CVEs, assets, or exploit steps.
- Keep each bullet grounded in the inputs.
- Use "Unknown" when missing.
- Keep output concise; prioritize clarity.

Task:
Summarize this chunk into:
A) Key counts (findings per severity, per tool)
B) Top themes (group similar findings)
C) A small list of notable findings (include finding_id + severity + title)

Mode: {mode}
Chunk: {chunk_index}/{total_chunks}
"""
    return rules.strip() + "\n\nINPUT_FINDINGS_JSON:\n" + json.dumps(items, indent=2)

def build_reduce_prompt(chunk_summaries: List[str], mode: str, dup_pairs: List[Tuple[str, str]]) -> str:
    """
    Reduce prompt merges chunk summaries into final report.
    """
    rules = f"""
You are a security REPORT MERGER drafting assistant running OFFLINE on a local machine.

Hard rules:
- Do NOT invent or change severity levels.
- Do NOT generate any overall risk score.
- Do NOT invent CVEs, assets, or exploit steps.
- If a fact is not in chunk summaries, write "Unknown".
- Keep content analyst-friendly.

You must output Markdown with EXACTLY these sections:
1) Executive Summary (no new severities)
2) Findings by Source Tool
3) Findings by Severity (as-reported)
4) Findings by Category (OWASP / IaC / Cloud / Dependencies / Network / AI)
5) Suspected Duplicates (use the duplicate map provided)
6) Analyst Next Actions checklist
7) Appendix: Evidence counts per tool

Mode: {mode}
"""
    payload = {
        "chunk_summaries": chunk_summaries,
        "duplicate_pairs": dup_pairs[:2000],  # cap
        "note": "Duplicate pairs are (kept_finding_id, duplicate_finding_id). Do not invent relationships beyond this list.",
    }
    return rules.strip() + "\n\nINPUT:\n" + json.dumps(payload, indent=2)

# ----------------------------
# Fallback markdown (no LLM)
# ----------------------------
def render_fallback_md(findings: List[Finding], mode: str, dup_pairs: List[Tuple[str, str]]) -> str:
    by_tool: Dict[str, List[Finding]] = {}
    by_sev: Dict[str, List[Finding]] = {s: [] for s in SEV_ORDER}
    by_cat: Dict[str, List[Finding]] = {}

    for f in findings:
        by_tool.setdefault(f.tool, []).append(f)
        by_sev.setdefault(f.severity, []).append(f)
        by_cat.setdefault(f.category or "Unknown", []).append(f)

    lines = []
    lines.append(f"# Consolidated Security Report ({mode})\n")
    lines.append("## Executive Summary\n")
    lines.append(f"- Total findings (deduped): {len(findings)}")
    lines.append("- Severity counts (as-reported):")
    for s in SEV_ORDER:
        lines.append(f"  - {s}: {len(by_sev.get(s, []))}")
    lines.append("")

    lines.append("## Findings by Source Tool\n")
    for tool, items in sorted(by_tool.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        lines.append(f"### {tool} ({len(items)})")
        for f in items[:40]:
            lines.append(f"- [{f.severity}] {f.finding_id} {f.title} — {f.resource}".strip())
        lines.append("")

    lines.append("## Findings by Severity (as-reported)\n")
    for s in SEV_ORDER:
        items = by_sev.get(s, [])
        if not items:
            continue
        lines.append(f"### {s} ({len(items)})")
        for f in items[:60]:
            lines.append(f"- {f.finding_id} {f.title} ({f.tool})")
        lines.append("")

    lines.append("## Findings by Category (OWASP / IaC / Cloud / Dependencies / Network / AI)\n")
    for cat, items in sorted(by_cat.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        lines.append(f"### {cat} ({len(items)})")
        for f in items[:40]:
            hint = f" {f.owasp_hint}" if f.owasp_hint else ""
            lines.append(f"- [{f.severity}]{hint} {f.finding_id} {f.title} ({f.tool})")
        lines.append("")

    lines.append("## Suspected Duplicates (use the duplicate map provided)\n")
    if not dup_pairs:
        lines.append("- None detected\n")
    else:
        lines.append(f"- Duplicate groups found: {len(dup_pairs)} (showing up to 50)\n")
        for a, b in dup_pairs[:50]:
            lines.append(f"- {a} duplicates {b}")
        lines.append("")

    lines.append("## Analyst Next Actions checklist\n")
    lines.append("- [ ] Validate all CRITICAL/HIGH findings directly in the environment")
    lines.append("- [ ] Confirm false positives vs real exposure")
    lines.append("- [ ] Create remediation tickets with owners + deadlines")
    lines.append("- [ ] Add/adjust detections for repeated patterns (auth failures, DB conn failures, VPN/BGP down)")
    lines.append("- [ ] Ensure no secrets/PHI appear in any logs or reports\n")

    lines.append("## Appendix: Evidence counts per tool\n")
    for tool, items in sorted(by_tool.items(), key=lambda kv: kv[0]):
        lines.append(f"- {tool}: {len(items)}")

    return "\n".join(lines)

# ----------------------------
# Main
# ----------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["tokyo", "ny", "both"], default="both")
    ap.add_argument("--input-dir", default="inputs")
    ap.add_argument("--output-dir", default="outputs")
    ap.add_argument("--llm", choices=["none", "ollama"], default="ollama")
    ap.add_argument("--ollama-url", default="http://localhost:11434/api/generate")
    ap.add_argument("--model", default="llama3.1")
    ap.add_argument("--chunk-size", type=int, default=120, help="findings per chunk for map step")
    args = ap.parse_args()

    in_base = Path(args.input_dir)
    out_base = Path(args.output_dir)
    out_base.mkdir(parents=True, exist_ok=True)

    modes = ["tokyo", "ny"] if args.mode == "both" else [args.mode]

    for m in modes:
        in_dir = in_base / m
        out_dir = out_base / m
        out_dir.mkdir(parents=True, exist_ok=True)

        findings: List[Finding] = []
        if in_dir.exists():
            for p in sorted(in_dir.glob("*.json")):
                findings.extend(parse_file(p))

        classify_defaults(findings)

        # ensure IDs
        for f in findings:
            if not f.finding_id:
                f.finding_id = stable_id(f.tool, f.severity, f.title, f.resource, f.cve)

        # Cross-tool dedupe
        deduped, dup_pairs = cross_tool_dedupe(findings)

        # Write extracted findings + duplicates map
        (out_dir / "extracted_findings.json").write_text(
            json.dumps([f.to_dict() for f in deduped], indent=2),
            encoding="utf-8"
        )
        (out_dir / "duplicate_map.json").write_text(
            json.dumps({"duplicate_pairs": dup_pairs}, indent=2),
            encoding="utf-8"
        )

        # LLM report generation: chunk summarize then reduce
        if args.llm == "ollama":
            chunks = chunk_findings(deduped, args.chunk_size)
            summaries: List[str] = []
            total = len(chunks) if chunks else 1
            try:
                for idx, ch in enumerate(chunks, start=1):
                    map_prompt = build_map_prompt(ch, mode=m, chunk_index=idx, total_chunks=total)
                    s = call_ollama(map_prompt, model=args.model, url=args.ollama_url)
                    summaries.append(sanitize_text(s))

                reduce_prompt = build_reduce_prompt(summaries, mode=m, dup_pairs=dup_pairs)
                md = call_ollama(reduce_prompt, model=args.model, url=args.ollama_url)
                md = sanitize_text(md)
            except Exception as e:
                md = f"# Consolidated Security Report ({m})\n\nLLM call failed: {e}\n\n" + render_fallback_md(deduped, mode=m, dup_pairs=dup_pairs)
        else:
            md = render_fallback_md(deduped, mode=m, dup_pairs=dup_pairs)

        (out_dir / "consolidated_security_report.md").write_text(md, encoding="utf-8")

        print(f"[{m}] wrote: {out_dir/'extracted_findings.json'}")
        print(f"[{m}] wrote: {out_dir/'duplicate_map.json'}")
        print(f"[{m}] wrote: {out_dir/'consolidated_security_report.md'}")

    print("Taris briefing complete. Malgus is satisfied.")

if __name__ == "__main__":
    main()
