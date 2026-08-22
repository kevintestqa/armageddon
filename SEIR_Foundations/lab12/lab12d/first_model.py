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

s3_client = boto3.client("s3")  # Initialize the S3 client
BUCKET_NAME = os.getenv("EVIDENCE_BUCKET")  # Use environment variable if available

if not BUCKET_NAME:
    raise RuntimeError(
        "EVIDENCE_BUCKET environment variable is required."
    )

def build_evidence():
    """Build and return one example ThreatEvidence object."""

    evidence = ThreatEvidence(
        identity=EvidenceIdentity(
            evidence_id="ev-001",
            provider_name="GitHub",
            provider_type=ProviderType.COMMERCIAL,
            provider_platform=PlatformType.MULTI_CLOUD,
        ),
        indicator=EvidenceIndicator(
            indicator_type=IndicatorType.TOKEN_ID,
            indicator_value="ghp_example",
            indicator_source=IndicatorSource.EXTERNAL_API,
            condition=ThreatCondition.TOKEN_EXPOSURE,
        ),
        context=EvidenceContext(
            severity=ThreatSeverity.HIGH,
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


upload = upload_evidence_to_s3(
    s3_client = s3_client,
    bucket_name = BUCKET_NAME, #Replace with actual bucket
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


# Attempt the download through the error-handling wrapper.
downloaded_evidence = safe_download_evidence_from_s3(
    s3_client=s3_client,
    bucket_name=BUCKET_NAME,
    object_key=s3_key,
)

# Only compare objects when the download was successful.
if downloaded_evidence is not None:
    print(
        "Cloud round trip:",
        downloaded_evidence == evidence,
    )
    

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


# Upload the evidence through the error-handling wrapper.
uploaded_key = safe_upload_evidence_to_s3(
    s3_client=s3_client,
    bucket_name=BUCKET_NAME,
    object_key=s3_key,
    evidence_json=evidence_json,
)

# Download only when the upload succeeded.
if uploaded_key is not None:
    downloaded_evidence = safe_download_evidence_from_s3(
        s3_client=s3_client,
        bucket_name=BUCKET_NAME,
        object_key=uploaded_key,
    )

    # Compare only when the download also succeeded.
    if downloaded_evidence is not None:
        print(
            "Cloud round trip:",
            downloaded_evidence == evidence,
        )