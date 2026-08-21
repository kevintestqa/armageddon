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

s3_client = boto3.client("s3")  # Initialize the S3 client
bucket_name = "sample-willocks-storage"  # Replace with your actual bucket name

# evidence = ThreatEvidence(
#     identity=EvidenceIdentity(
#         evidence_id="ev-001",
#         provider_name="AWS",
#         provider_type=ProviderType.CLOUD_NATIVE,
#         provider_platform=PlatformType.GITHUB,
#     ),
#     indicator=EvidenceIndicator(
#         indicator_type=IndicatorType.TOKEN_ID,
#         indicator_value="ghp_example",
#         indicator_source=IndicatorSource.EXTERNAL_API,
#         condition=ThreatCondition.TOKEN_EXPOSURE,
#     ),
#     context=EvidenceContext(
#         severity=ThreatSeverity.HIGH,
#     ),
# )

# print(evidence.describe())

# restored = ThreatEvidence.from_dict(evidence.to_dict())

# print("Round trip:", restored == evidence)


def build_evidence():
    """Build and return one example ThreatEvidence object."""

    evidence = ThreatEvidence(
        identity=EvidenceIdentity(
            evidence_id="ev-001",
            provider_name="GitHub",
            provider_type=ProviderType.CLOUD_NATIVE,
            provider_platform=PlatformType.GITHUB,
        ),
        indicator=EvidenceIndicator(
            indicator_type=IndicatorType.TOKEN_ID,
            indicator_value="ghp_example",
            indicator_source=IndicatorSource.EXTERNAL_API,
            condition=ThreatCondition.TOKEN_EXPOSURE,
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

print(
    "JSON round trip:",
    restored_from_json == evidence,
)

def upload_evidence_to_s3(s3_client, bucket_name, object_key, evidence_json):
    """Upload the JSON representation of ThreatEvidence to S3."""

    s3_client.put_object(
        Bucket = bucket_name,
        Key = object_key,
        Body = evidence_json,
        ContentType = "application/json"
    )
    
    return object_key


upload = upload_evidence_to_s3(
    s3_client = s3_client,
    bucket_name = bucket_name, #Replace with actual bucket
    object_key = s3_key,
    evidence_json = evidence_json)

print("Uploaded to S3 with key:", upload)

def download_evidence_from_s3(s3_client, bucket_name, object_key):
    s3_object = s3_client.get_object(
        Bucket = bucket_name,
        Key = object_key
    )
    s3_object_body = s3_object['Body'].read().decode('utf-8')
    restored_evidence = deserialize_evidence(s3_object_body)
    return restored_evidence

downloaded_evidence = download_evidence_from_s3(
    s3_client = s3_client,
    bucket_name = bucket_name, #Replace with actual bucket
    object_key = s3_key)

print( "Cloud round trip:",
    downloaded_evidence == evidence
    )