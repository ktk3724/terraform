# S3 수명 주기 규칙
resource "aws_s3_bucket_lifecycle_configuration" "artifact_lifecycle" {
  bucket = aws_s3_bucket.artifact_store.id

  rule {
    id     = "archive"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}