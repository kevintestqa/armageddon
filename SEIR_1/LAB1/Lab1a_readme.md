SEIR-I Lab 1
GCP Infrastructure + Azure Active Directory Identity Integration
Identity Is the System

Purpose of This Lab
This lab validates that you can operate identity as a first-class system, not as an afterthought.

By the time you reach this lab, you are expected to:
    understand GCP as a resource plane
    understand Azure Active Directory (Entra ID) as a trust plane
    reason about who is trusted, why, and with what blast radius
    automate carefully, not eagerly
    prove outcomes with evidence, not confidence

This lab does not reward speed.
It rewards discipline.

Scenario
You are designing access for a small but real system:
    Google Cloud Platform (GCP) hosts infrastructure resources.
    Azure Active Directory (Entra ID) is the sole identity provider.
    Human users must not be created locally in GCP.
    Access must be federated, auditable, and recoverable.

Your job is to implement this correctly and prove that it works.

High-Level Architecture (What You Are Building)
User
  ↓
Azure Active Directory (Entra ID)
  ↓  (Federation / Trust)
GCP Workforce Identity Federation
  ↓
GCP Project Resources

There are two planes:
    Trust Plane: Azure AD
    Resource Plane: GCP

They must remain distinct.

Lab Objectives (All Required)
1. GCP Foundation
You must:
    Create a GCP project
    Configure minimal networking
    Enable logging and audit logs
    Deploy one compute resource (VM or equivalent)

The resource must not be publicly accessible by default.

2. Azure AD Identity Structure
You must:
    Use an existing Azure AD tenant
    Create groups, not user-based assignments
    Clearly document:
      which group represents access
      why that group exists

No hard-coded users.
No direct assignments.

3. Workforce Identity Federation
You must:
    Configure Azure AD as the identity provider
    Configure GCP Workforce Identity Federation
    Map Azure AD groups to specific GCP IAM roles

Access must follow least privilege.

4. Federated Access Verification
You must prove:
    A user authenticated via Azure AD
    Accessed GCP resources
    Without a local GCP user account

This proof must include logs.

5. Evidence Collection (Mandatory)
You must collect and submit:
    GCP audit logs showing access
    Azure AD sign-in logs
    A written explanation of what happened

If it isn’t logged, it didn’t happen.

6. Automation (Careful and Limited)
PowerShell (Required)
You must provide read-only PowerShell scripts that:
    List Azure AD users and groups
    Show group membership relevant to this lab

Write access is not allowed.

Python (Optional, Bonus)
If used, Python may:
    Parse logs
    Validate access events
    Summarize evidence

Python must not change identity or access.

What Is Explicitly Forbidden
    Creating local IAM users in GCP
    Assigning permissions directly to users
    Using service accounts for human access
    “Just making it work” without explanation
    Removing logs to hide mistakes
    Blind automation without understanding

Any of the above is an automatic lab failure.

Failure & Recovery (Required Explanation)
You must include a short section titled:
    “If This Breaks”

It must explain:
    what would fail first
    how access could be restored
    which steps must be manual
    why those steps should not be automated

Submission Requirements

You must submit:
1) Architecture Diagram
    Identity plane vs resource plane clearly labeled

2) Access Justification Document
    Who can access
    Why
    What they cannot access

3) Logs (Screenshots or Exports)
    Azure AD sign-in
    GCP audit entry

4) Scripts
    PowerShell (read-only)
    Python (if used)

5) Written Reflection (Short)
    What was hardest
    What you would do differently
    What you refused to automate

Grading Philosophy
You are graded on:
    correctness
    restraint
    clarity
    evidence

You are not graded on:
    speed
    clever tricks
    how much code you wrote

A simple, correct solution scores higher than a complex, fragile one.

What This Lab Proves
If you pass this lab, you have demonstrated that you can:
    treat identity as infrastructure
    integrate clouds without chaos
    operate within trust boundaries
    recover from mistakes calmly
    explain your decisions under scrutiny

That is SEIR-I.
