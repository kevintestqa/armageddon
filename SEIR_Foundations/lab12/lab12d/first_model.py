from models.enums import (
    IndicatorSource,
    IndicatorType,
    PlatformType,
    ProviderType,
    ThreatCondition,
    ThreatSeverity,
)
from models.evidence import (
    EvidenceContext,
    EvidenceIdentity,
    EvidenceIndicator,
    ThreatEvidence,
)

import json
import boto3
from botocore.exceptions import BotoCoreError, ClientError
import os

def build_evidence():
    """Build and return one example ThreatEvidence object."""

    evidence = ThreatEvidence(
        identity=EvidenceIdentity(
            evidence_id="ev-011",
            provider_name="Pawserenity.co",
            provider_type=ProviderType.COMMUNITY,
            provider_platform=PlatformType.AWS,
        ),
        indicator=EvidenceIndicator(
            indicator_type=IndicatorType.SHA256,
            indicator_value="ghp_example",
            indicator_source=IndicatorSource.APPLICATION_LOG,
            condition=ThreatCondition.UNAUTHENTICATED_ENDPOINT,
        ),
        context=EvidenceContext(
            severity=ThreatSeverity.CRITICAL,
        ),
    )

    return evidence


# Call the function and save the returned object in the evidence variable.
evidence = build_evidence()

# Display a human-readable description.
print(evidence.describe())

# Serialize and reconstruct the evidence.
restored = ThreatEvidence.from_dict(evidence.to_dict())

# Confirm that reconstruction did not change its meaning.
print("Round trip:", restored == evidence)


def build_s3_key(evidence):
    """Build an S3 object key using severity and evidence ID."""

    severity = evidence.context.severity.name.lower()
    evidence_id = evidence.identity.evidence_id

    return (
        f"evidence/severity={severity}/"
        f"{evidence_id}.json"
    )
    
s3_key = build_s3_key(evidence)
print("S3 key:", s3_key)


def serialize_evidence(evidence):
    """Convert a ThreatEvidence object into formatted JSON text."""

    evidence_dictionary = evidence.to_dict()

    evidence_json = json.dumps(
        evidence_dictionary,
        indent=2,
    )

    return evidence_json

evidence_json = serialize_evidence(evidence)

print("Evidence JSON:")
print(evidence_json)


def deserialize_evidence(evidence_json):
    """Reconstruct ThreatEvidence from JSON text."""

    evidence_dictionary = json.loads(evidence_json)

    restored_evidence = ThreatEvidence.from_dict(
        evidence_dictionary
    )

    return restored_evidence

restored_from_json = deserialize_evidence(evidence_json)

def upload_evidence_to_s3(s3_client, bucket_name, object_key, evidence_json):
    """Upload the JSON representation of ThreatEvidence to S3."""

    s3_client.put_object(
        Bucket = bucket_name,
        Key = object_key,
        Body = evidence_json,
        ContentType = "application/json"
    )
    
    return object_key

def download_evidence_from_s3(s3_client, bucket_name, object_key):
    s3_object = s3_client.get_object(
        Bucket = bucket_name,
        Key = object_key
    )
    s3_object_body = s3_object['Body'].read().decode('utf-8')
    restored_evidence = deserialize_evidence(s3_object_body)
    return restored_evidence

def safe_download_evidence_from_s3(
    s3_client,
    bucket_name,
    object_key,
):
    """Download evidence and handle expected S3 errors safely."""

    # Reject an empty key before sending a request to AWS.
    if not object_key or not object_key.strip():
        print("S3 download failed: object key cannot be empty.")
        return None

    try:
        # Use the original download function for the normal success path.
        return download_evidence_from_s3(
            s3_client=s3_client,
            bucket_name=bucket_name,
            object_key=object_key,
        )

    except ClientError as error:
        # Extract the short AWS error code from the full response.
        error_code = error.response["Error"]["Code"]

        # Translate common AWS codes into human-readable explanations.
        error_messages = {
            "NoSuchBucket": "The S3 bucket does not exist.",
            "NoSuchKey": "The evidence object was not found.",
            "AccessDenied": "AWS denied permission to read the object.",
            "InvalidBucketName": "The S3 bucket name is invalid.",
        }

        # Use a general message if AWS returns an unfamiliar error code.
        message = error_messages.get(
            error_code,
            "An unexpected S3 error occurred.",
        )

        print(
            f"S3 download failed [{error_code}]: "
            f"{message}"
        )

        # None tells the caller that no ThreatEvidence object was returned.
        return None
    

def safe_upload_evidence_to_s3(
    s3_client,
    bucket_name,
    object_key,
    evidence_json,
):
    """Upload evidence and handle expected S3 errors safely."""

    # Reject an empty key before sending a request to AWS.
    if not object_key or not object_key.strip():
        print("S3 upload failed: object key cannot be empty.")
        return None

    # Reject an empty JSON string before sending a request to AWS.
    if not evidence_json or not evidence_json.strip():
        print("S3 upload failed: evidence JSON cannot be empty.")
        return None
    
    # Reject an empty bucket name before contacting AWS.
    if not bucket_name or not bucket_name.strip():
        print("S3 upload failed: bucket name cannot be empty.")
        return None

    try:
        # Use the original upload function for the normal success path.
        return upload_evidence_to_s3(
            s3_client=s3_client,
            bucket_name=bucket_name,
            object_key=object_key,
            evidence_json=evidence_json,
        )

    except ClientError as error:
        # Extract the short AWS error code from the full response.
        error_code = error.response["Error"]["Code"]

        # Translate common AWS codes into human-readable explanations.
        error_messages = {
            "NoSuchBucket": "The S3 bucket does not exist.",
            "NoSuchKey": "The evidence object was not found.",
            "AccessDenied": "AWS denied permission to put the object.",
            "InvalidBucketName": "The S3 bucket name is invalid.",
        }

        # Use a general message if AWS returns an unfamiliar error code.
        message = error_messages.get(
            error_code,
            "An unexpected S3 error occurred.",
        )

        print(
            f"S3 upload failed [{error_code}]: "
            f"{message}"
        )

        # None tells the caller that no ThreatEvidence object was returned.
        return None


def publish_evidence_metrics(cloudwatch_client, evidence):
    severity = evidence.context.severity.value
    provider = evidence.identity.provider_name
    indicator_type = evidence.indicator.indicator_type.value

    metric_data = [
        {
            "MetricName": "EvidenceTotal",
            "Value": 1,
            "Unit": "Count",
        },
        {
            "MetricName": "EvidenceBySeverity",
            "Dimensions": [
                {
                    "Name": "Severity",
                    "Value": severity,
                }
            ],
            "Value": 1,
            "Unit": "Count",
        },
        {
            "MetricName": "EvidenceByProvider",
            "Dimensions": [
                {
                    "Name": "Provider",
                    "Value": provider,
                }
            ],
            "Value": 1,
            "Unit": "Count",
        },
        {
            "MetricName": "EvidenceByIndicatorType",
            "Dimensions": [
                {
                    "Name": "IndicatorType",
                    "Value": indicator_type,
                }
            ],
            "Value": 1,
            "Unit": "Count",
        },
    ]

    cloudwatch_client.put_metric_data(
        Namespace="Armageddon/ThreatEvidence",
        MetricData=metric_data,
    )
    
def create_cloudwatch_dashboard(cloudwatch_client):
    """Create the threat-monitoring CloudWatch dashboard."""

    dashboard_body = {
        "start": "-PT3H",
        "periodOverride": "inherit",
        "widgets": [
            {
                "type": "metric",
                "x": 0,
                "y": 0,
                "width": 6,
                "height": 6,
                "properties": {
                    "title": "Total Evidence Processed",
                    "view": "singleValue",
                    "region": "us-west-1",
                    "stat": "Sum",
                    "period": 300,
                    "metrics": [
                        [
                            "Armageddon/ThreatEvidence",
                            "EvidenceTotal",
                        ]
                    ],
                },
            },
            {
                "type": "metric",
                "x": 6,
                "y": 0,
                "width": 9,
                "height": 6,
                "properties": {
                    "title": "Evidence by Severity",
                    "view": "bar",
                    "region": "us-west-1",
                    "stat": "Sum",
                    "period": 300,
                    "metrics": [
                        [
                            {
                                "expression": (
                                    "SEARCH("
                                    "'{Armageddon/ThreatEvidence,Severity} "
                                    "MetricName=\"EvidenceBySeverity\"', "
                                    "'Sum', 300)"
                                ),
                                "id": "severity_search",
                            }
                        ]
                    ],
                },
            },
            {
                "type": "metric",
                "x": 15,
                "y": 0,
                "width": 9,
                "height": 6,
                "properties": {
                    "title": "Evidence by Indicator Type",
                    "view": "pie",
                    "region": "us-west-1",
                    "stat": "Sum",
                    "period": 300,
                    "metrics": [
                        [
                            {
                                "expression": (
                                    "SEARCH("
                                    "'{Armageddon/ThreatEvidence,IndicatorType} "
                                    "MetricName=\"EvidenceByIndicatorType\"', "
                                    "'Sum', 300)"
                                ),
                                "id": "indicator_search",
                            }
                        ]
                    ],
                },
            },
        ],
    }

    response = cloudwatch_client.put_dashboard(
        DashboardName="Armageddon-Threat-Monitoring-Automated",
        DashboardBody=json.dumps(dashboard_body),
    )

    print("Created CloudWatch dashboard.")
    return response

def main():
    """Run the live S3 evidence demonstration."""

    cloudwatch_client = boto3.client(
        "cloudwatch",
        region_name="us-west-1",
    )

    create_cloudwatch_dashboard(cloudwatch_client)

    bucket_name = os.getenv("EVIDENCE_BUCKET")

    if not bucket_name:
        raise RuntimeError(
            "EVIDENCE_BUCKET environment variable is required."
        )

    s3_client = boto3.client("s3")
    evidence = build_evidence()
    evidence_json = serialize_evidence(evidence)
    s3_key = build_s3_key(evidence)

    uploaded_key = safe_upload_evidence_to_s3(
        s3_client=s3_client,
        bucket_name=bucket_name,
        object_key=s3_key,
        evidence_json=evidence_json,
    )

    if uploaded_key is not None:
        publish_evidence_metrics(
            cloudwatch_client=cloudwatch_client,
            evidence=evidence,
        )

        downloaded_evidence = safe_download_evidence_from_s3(
            s3_client=s3_client,
            bucket_name=bucket_name,
            object_key=uploaded_key,
        )

        if downloaded_evidence is not None:
            print(
                "Cloud round trip:",
                downloaded_evidence == evidence,
            )

if __name__ == "__main__":
    main()