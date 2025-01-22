# 먼저 파일 상단에 로컬 변수로 공통 태그 정의
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}

# 파이프라인 아티팩트를 저장할 S3 버킷 생성
resource "aws_s3_bucket" "artifact_store" {
  bucket = "${var.project_name}-artifacts-${var.environment}"
tags = local.common_tags
}

# S3 버킷 버전 관리 활성화
resource "aws_s3_bucket_versioning" "artifact_store_versioning" {
  bucket = aws_s3_bucket.artifact_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CodePipeline을 위한 IAM 역할 생성
resource "aws_iam_role" "pipeline_role" {
  name = "${var.project_name}-pipeline-role"

  # 신뢰 정책 설정 (CodePipeline이 이 역할을 사용할 수 있도록 함)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
  tags = local.common_tags
}

# CodePipeline IAM 역할에 정책 연결
resource "aws_iam_role_policy" "pipeline_policy" {
  name = "${var.project_name}-pipeline-policy"
  role = aws_iam_role.pipeline_role.id

  # 파이프라인에 필요한 권한 설정
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",          # S3 관련 권한
          "codecommit:*",  # CodeCommit 관련 권한
          "codebuild:*"    # CodeBuild 관련 권한
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild 프로젝트 설정
resource "aws_codebuild_project" "build_project" {
  name          = "${var.project_name}-build"
  description   = "Build project for ${var.project_name}"
  service_role  = aws_iam_role.pipeline_role.arn

  # 아티팩트 설정
  artifacts {
    type = "CODEPIPELINE"
  }

  # 빌드 환경 설정
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"  # 컴퓨팅 타입
    image                      = "aws/codebuild/standard:5.0"  # 빌드 환경 이미지
    type                       = "LINUX_CONTAINER"
    privileged_mode            = true  # 도커 빌드를 위한 권한 설정
  }

  # 소스 설정
  source {
    type      = "CODEPIPELINE"
    buildspec = "config/buildspec.yml"  # 빌드 스펙 파일 위치
  }
  tags = local.common_tags
}

# CodePipeline 생성
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  # 아티팩트 저장소 설정
  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  # 소스 스테이지 설정
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"  # 소스 제공자
      version          = "1"
      output_artifacts = ["source_output"]  # 소스 코드 아티팩트

      configuration = {
        RepositoryName = "${var.project_name}-repo"
        BranchName     = "main"
      }
    }
  }

  # 빌드 스테이지 설정
  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]  # 이전 스테이지의 출력을 입력으로 사용
      version         = "1"
      
      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
         tags = local.common_tags
      }
    }
  }
  # ECS 배포 스테이지 추가
stage {
  name = "Deploy"
  action {
    name            = "Deploy"
    category        = "Deploy"
    owner           = "AWS"
    provider        = "ECS"
    input_artifacts = ["source_output"]
    version         = "1"

    configuration = {
      ClusterName = "${var.project_name}-cluster"
      ServiceName = "${var.project_name}-service"
      FileName    = "imagedefinitions.json"
    }
  }
}
}

