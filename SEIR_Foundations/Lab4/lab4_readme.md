
Lab 4 — Japan Medical
Multi-Cloud Reality in Regulated Healthcare

⚖️ Why This Lab Exists
Many engineers fail in real life because:
    They optimize locally
    They assume uniform platforms
    They treat compliance as “someone else’s problem”

This lab teaches:
    Cross-cloud thinking
    Legal translation into architecture
    Responsibility beyond your own stack
    Professional restraint

🎯 What This Lab Is About

In this lab, you are not solving a technical problem first.
You are solving a human, legal, and organizational problem.

A Japanese medical center operates globally.
    Tokyo is the data authority
    Compliance is non-negotiable
    And now:
      The New York branch refuses to use AWS.

Instead, they deploy on Google Cloud Platform (GCP).
No negotiations. No exceptions.
Your job is not to convince them otherwise.
Your job is to make the system work — legally and responsibly.

🧠 The First Reality: Technology Is Not the Decision
Many engineers assume:
    “If we pick the right platform, the problem goes away.”

In real organizations:
    Technology choices are political
    Vendor preferences exist
    Contracts predate architecture
    Teams have autonomy
    Mergers create fragmentation

You will encounter:
    AWS in one region
    GCP in another
    Azure somewhere else
    Oracle, IBM, OpenShift, or on-prem in legacy branches

📌 Compliance does not change just because technology does.


🏥 Legal Constraint Still Applies (This Does Not Change)
Even in a multi-cloud world:
    --> Japanese patient medical data (PHI) must be stored only in Japan.

This rule does not bend for:
    GCP
    Azure
    “Better latency”
    “Local autonomy”
    “It’s inconvenient”

There is:
    No exemption
    No workaround
    No “temporary” exception


🌎 What the New York Branch Is Allowed to Do
The New York branch (on GCP) may:
    Deploy compute only (VMs, autoscaling groups)
    Serve doctors locally
    Authenticate users
    Process requests in memory
    Call APIs across providers
    Read and write data remotely

The New York branch may not:
    Store patient data at rest
    Deploy databases
    Cache medical records
    Replicate data
    Snapshot, export, or log PHI

This is exactly the same rule as São Paulo — the platform changed, the law did not.

🔗 Connectivity Must Respect Compliance
You are now operating across:
    Cloud providers
    Legal jurisdictions
    Organizational boundaries

The system must ensure:
    Secure connectivity from GCP → Japan
    Clear network paths
    Encryption in transit
    Strong identity and access controls
    Complete auditability

And critically:
    --> No accidental data persistence outside Japan

This includes:
    Disk
    Logs
    Queues
    Caches
    Backups
    Temporary files

🧑‍⚕️ Focus on the Human Experience
    This lab is not just infrastructure.
    You must consider three people:

👩‍⚕️ Doctor (New York)
Expectations:
    Fast, reliable access to patient records
    No concern about where data lives
    No manual compliance steps
    Trust that the system is legal

Risks:
    Latency
    Connectivity failures
    Partial outages

Your responsibility:
    --> Design systems where doctors never have to think about compliance — because you already did.


🧑‍🦽 Patient (Japanese Citizen)
Expectations:
    Their data is protected
    Their data is not exported
    Their rights are respected
    Their records are accurate

Patients do not care about:
    AWS vs GCP
    Cloud vendors
    Network topology

They care about:
    --> Trust

Your responsibility:
    --> Architect in a way that never betrays that trust.

🧑‍💼 Manager / Executive
Expectations:
    Branch autonomy
    Regulatory safety
    No headlines
    No fines
    No “why didn’t you tell us?”

Managers expect engineers to:
    Anticipate risk
    Explain tradeoffs clearly
    Say “no” when required
    Provide defensible designs

Your responsibility:
    --> Make compliance boring and invisible.

🧠 The Core Lesson of Lab 4
    You do not control the technology landscape.
    You control how responsibly it is connected.

Multi-cloud is not a badge of honor.
It is a constraint.

Good engineers complain.
Great engineers adapt without breaking the law.


🗣️ How You Should Talk About This Lab
  If asked in an interview:
      “We supported a medical branch on GCP while keeping all PHI in Japan.
      The branch ran stateless compute only, and all patient data was accessed remotely under strict controls.
      Compliance dictated the architecture — not cloud preference.”

That answer signals maturity.





