## LAB-B — INCIDENT RESPONSE RUNBOOK
**ACKNOWLEDGE AND OBSERVE**
**STEP 1 — Acknowledge the Alert (MANDATORY FIRST STEP)**

```
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
```

> [!NOTE]
> What do  you see? Did an alert trigger? 

**STEP 2 — Identify What the Alarm Is Measuring**

```
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].Metrics"
```

> [!NOTE]
> Is this performance information about the system? 

**STEP 3 — Check Application Logs (Primary Evidence)**


**3.1 Identify Log Streams**

```
aws logs describe-log-streams \
  --log-group-name /aws/ec2/rds-logs \
  --order-by LastEventTime \
  --descending
```

> [!NOTE]
> What information can you gain from the nature of the logs? 


**3.2 Pull Recent Errors**

```
aws logs get-log-events \
  --log-group-name /aws/ec2/rds-logs \
  --log-stream-name <LATEST_STREAM_NAME> \
  --limit 50
```


> [!NOTE]
> **Can you see:**
> - Access denied for user
>
> - Can't connect to MySQL server
> 
> - Connection timed out
>
> - OperationalError


>[!NOTE]
> What has the errors told you about this incident? 


**PART II — DIAGNOSIS (NO CHANGES YET)**

**You must now determine which failure class this is.**

**STEP 4 — Validate Configuration Sources (NOT VALUES)**

**4.1 Confirm Secrets Are Being Used**

```
aws secretsmanager describe-secret \
  --secret-id rds_secrets_mnger
```

> [!NOTE]
> **Can you see:**
>
> - Secret exists
>
> - No deletion
>
> - Rotation state visible

**4.2 Confirm DB Connection Metadata (SSM)**

```
aws ssm get-parameters \
  --names /lab/db/host /lab/db/port /lab/db/name \
  --with-decryption
```

>[!NOTE]
> **Can you see:**
>
> - Hostname resolves
>
> - Port is 3306
>
> - DB name matches RDS

**STEP 5 — Check Network Reachability (Without Changing Anything)**

**5.1 Verify RDS Security Group Rules**

```
aws ec2 describe-security-groups \
  --group-ids <RDS_SG_ID>
```



> [!NOTE]
> **Can you see:**
>
> - Inbound rule allows EC2 SG → TCP 3306
>
> - If missing → likely Option B (Network Isolation).

*STEP 6 — Check RDS Health**

```
aws rds describe-db-instances \
  --db-instance-identifier <DB_ID> \
  --query "DBInstances[].DBInstanceStatus"
```

> [!NOTE]
> **Can you see:**
>
> - **"available"**


**If stopped → Option C (DB Interruption).**

**PART III — FAILURE CLASS IDENTIFICATION**

**At this point you should know which of the three occurred.**

> **Symptom	Root Cause**
>
> - Access denied errors	Option A — Secret Drift
> - Timeout / can't reach host	Option B — Network Isolation
> - RDS stopped	Option C — DB Interruption
>
>**You are not told which one — you're at the point where you can prove it.**


**PART IV — RECOVERY (ONLY AFTER DIAGNOSIS)**
 **OPTION A — SECRET DRIFT**
> **Root Cause**
>
> - Secret was changed
>
> - RDS password was not

**Recovery Steps (Correct & Minimal)**

```
aws secretsmanager update-secret \
  --secret-id rds_secrets_mnger \
  --secret-string file://correct-db-creds.json
```



**Then restart app process only:**

```
sudo systemctl restart app
```


**OPTION B — NETWORK ISOLATION**
> **Root Cause**
>
> - EC2 SG removed from RDS inbound rule

**Recovery**

```
aws ec2 authorize-security-group-ingress \
  --group-id <RDS_SG_ID> \
  --protocol tcp \
  --port 3306 \
  --source-group <EC2_SG_ID>
```


**OPTION C — DB INTERRUPTION**
> **Root Cause**
>
> - RDS manually stopped
>
**Recovery**

```
aws rds start-db-instance \
  --db-instance-identifier <DB_ID>
```

**Wait until you see:**

**"available"**

**PART V — VALIDATION (MANDATORY)**


**STEP 1 — Confirm Alarm Clears**

```
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
```



> **You should see:**
>
> **"OK"**

**STEP 2 — Confirm Logs Stabilize**

> - No new DB errors
> 
> - Successful connection messages

**STEP 3 — Confirm Application Endpoint**

```
curl http://<EC2_IP>/list
```

> **Expected:**
>
> - HTTP 200
>
> - No hang
