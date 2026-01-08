SEIR-I Lab 1B
Integrating Google Managed Database with an Existing GCP VM
Data Is a Trust Multiplier

Purpose of This Lab
This lab extends SEIR-I Lab 1a by introducing a managed database into the system without breaking identity discipline.

You are proving that you can:
    add data infrastructure safely
    preserve trust boundaries
    restrict network and identity access
    validate access using evidence
    refuse unsafe shortcuts

This lab is not about database performance.
It is about control.

Prerequisite (Mandatory)
You must have successfully completed:
    SEIR-I Lab 1a – GCP Infrastructure + Azure AD Identity

Specifically:
    GCP project exists
    VM exists
    Azure AD federation is working
    Access is group-based
    Logs are enabled and verifiable

If Lab 1a is incomplete, stop here.

Scenario
You are asked to add a Google-managed database to the system.

Requirements:
    The database must not be publicly accessible
    Only the existing GCP VM may connect to it
    Human users must not connect directly
    Identity and network controls must be enforced
    Access must be auditable

You are responsible for deciding how to do this safely.

High-Level Architecture (After Lab 1B)

User
  ↓
Azure AD (Entra ID)
  ↓
GCP Workforce Identity Federation
  ↓
GCP VM
  ↓
Google Managed Database (Private Access)


Two trust boundaries now exist:
    Human → VM (identity)
    VM → Database (network + service identity)

They must remain separate.

Allowed Database Options (Choose One)
You may use one of the following:
    Cloud SQL (PostgreSQL or MySQL)
    AlloyDB (if available to you)

Firestore is not allowed for this lab.

Lab Objectives (All Required)
1. Database Deployment
    You must:
      Deploy a managed Google database
      Use private IP only
      Disable public access
      Enable logging/audit features

    You must document:
      why this database was chosen
      why it is not publicly reachable

2. Network Access Control
    You must:
      Ensure only the existing VM can reach the database
      Use VPC controls (not IP whitelisting hacks)
      Clearly explain the blast radius

Opening access to 0.0.0.0/0 is an automatic failure.

3. VM-to-Database Authentication
    You must:
      Use a service account for the VM
      Assign least privilege roles
      Explain why humans do not authenticate directly

Hard-coded credentials are forbidden.

4. Application Connectivity (Minimal)
On the VM, you must:
    Install a simple database client
    Perform:
      one successful read
      one successful write

No application framework is required.
This is proof of access — nothing more.

5. Evidence Collection (Mandatory)
    You must collect:
      GCP audit logs showing database access
      Network flow or connection evidence
      Service account usage evidence

    Logs must show:
      who accessed
      from where
      what was allowed

Automation Rules
    PowerShell
      May be used to inspect Azure AD groups
      May NOT modify database access

  Python (Optional but Encouraged)
    Python may:
      Validate DB connectivity
      Log access attempts
      Parse audit logs

   Python may NOT:
      manage identity
      create users
      rotate credentials automatically

What Is Explicitly Forbidden
    Public database endpoints
    Human DB credentials
    Passwords in code
    Storing secrets in plain text
    “Just testing” rules left behind
    Skipping logging because “it worked”

Any of these = lab failure.

Failure & Recovery (Required Section)
You must include a section titled:
      “If Database Access Fails”

It must explain:
    first signal of failure
    how you would diagnose it
    which logs matter
    how you would restore access safely
    what you would not automate

Submission Requirements
You must submit:
  1) Updated Architecture Diagram
        Identity plane
        Compute plane
        Data plane

  2) Database Access Justification
      Why this VM
      Why this service account
      Why these permissions

  3) Logs
      DB audit entries
      VM access evidence

  4) Scripts
      PowerShell (identity inspection)
      Python (if used)

  5) Reflection
      What you were tempted to shortcut
      Why you didn’t

Grading Philosophy
You are graded on:
    isolation
    restraint
    auditability
    clarity of reasoning

You are not graded on:
    schema design
    performance tuning
    clever hacks

What This Lab Proves
If you pass Lab 1B, you have shown that you can:
    add data without chaos
    protect managed services
    respect trust boundaries
    debug connectivity failures calmly
    treat databases as high-risk assets

This is identity-aware systems engineering.


