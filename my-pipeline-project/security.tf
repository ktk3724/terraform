# KMS 키 생성
resource "aws_kms_key" "pipeline_key" {
  description             = "파이프라인 암호화 키"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# S3 버킷 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "artifact_encryption" {
  bucket = aws_s3_bucket.artifact_store.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.pipeline_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# VPC 엔드포인트 설정
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}