### SEIR Lab 2 Gate Result: **YELLOW** (PASS)

**Domain:** `www.pawserenity.click`  
**CloudFront:** `E1NDJHX217QYY1` (domain: `d1vj1sb7iuwnf9.cloudfront.net`)  
**WAF required:** `true`  
**Logging required:** `true`  
**Origin SG:** `sg-0e29a282ce7b392f7`  

**SLA**
- target: `24h`
- first_seen: ``
- due: ``
- breached: `false`

**Failures (fix in order)**
- (none)

**Warnings**
- WARN: Origin SG sg-0e29a282ce7b392f7 has no visible sources on port 443 (check prefix lists / LB SG chaining).
- WARN: Origin SG sg-0e29a282ce7b392f7 has no visible sources on port 80 (check prefix lists / LB SG chaining).

> Reminder: Hennessy does not fix Route53 alias records. Evidence does.
