from first_model import safe_upload_evidence_to_s3

def test_safe_upload_rejects_empty_bucket_name():
    result = safe_upload_evidence_to_s3(
        s3_client=None,
        bucket_name="",
        object_key="evidence/test.json",
        evidence_json="{}",
    )

    assert result is None


def test_safe_upload_rejects_empty_key():
    result = safe_upload_evidence_to_s3(
        s3_client=None,
        bucket_name="sample_bucket_name",
        object_key="",
        evidence_json="{}",
    )

    assert result is None


def test_safe_upload_rejects_empty_evidence_json():
    result = safe_upload_evidence_to_s3(
        s3_client=None,
        bucket_name="sample_bucket_name",
        object_key="evidence/test.json",
        evidence_json="",
    )

    assert result is None