# AWS 리전 변수
variable "aws_region" {
  description = "AWS 리전"
  default     = "ap-northeast-2"
}

# 프로젝트 이름 변수
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

# 환경 구분 변수 (dev, staging, prod)
variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "notification_email" {
  description = "알림을 받을 이메일 주소"
  type        = string
}

variable "retention_days" {
  description = "로그 보존 기간"
  type        = number
  default     = 30
}