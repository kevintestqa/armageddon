Lab 5A — Red Team
“Break It Like a Professional (Without Breaking the Law)”

Objective
Red Team simulates realistic attacker behavior against the systems you built in Labs 1–4:
    AWS Tokyo = authoritative data + compliance boundary
    GCP NY/Iowa = compute-only branch + VPN corridor
    AI drafting exists (Bedrock/Vertex) but must remain human-governed

Red Team’s mission is to discover and demonstrate risk, not to cause damage.

Scope and Rules of Engagement (ROE)
✅ Allowed Targets (Lab Environment Only)
    NY GCP private app URL (reachable only from inside VPN corridor)
    Tokyo app components that are explicitly in-scope for the lab
    Your own lab VPCs/subnets
    Your own accounts/projects only

❌ Forbidden
    Any public internet scanning outside the lab
    Any brute-force password attacks
    Any attempts to access real PHI (none should exist in lab)
    Any destructive actions (deleting resources, wiping DB, crypto-mining, DoS)
    Any persistence/backdoors beyond what the lab explicitly allows

Rate limits (to prevent “accidental DoS”)
    Web scanners: cap to low thread counts, modest request rate
    Port scans: limited to specific CIDRs/hosts you own

Logging requirement
Red Team must maintain an activity log:
    timestamp
    tool used
    target
    goal
    result
    evidence artifact path

This becomes part of the audit defense later.

The Red Team Mindset (What You’re Practicing)
Red Team is trained to find:
    Broken assumptions
    Misconfigurations
    Over-permissive access
    Missing monitoring
    Unsafe defaults

You are not “being evil.” You are being useful.
