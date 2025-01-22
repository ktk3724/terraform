# AWS 프로바이더 설정
provider "aws" {
  region = var.aws_region
}

# 테라폼 설정 블록
terraform {
  # AWS 프로바이더 버전 지정
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # 테라폼 상태 파일을 저장할 S3 백엔드 설정
  backend "s3" {
    bucket         = "my-terraform-state"    # 상태 파일을 저장할 S3 버킷
    key            = "pipeline/terraform.tfstate"  # 상태 파일 경로
    region         = "ap-northeast-2"
    encrypt        = true  # 암호화 활성화
  }
}