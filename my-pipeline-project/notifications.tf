# SNS 토픽 생성
resource "aws_sns_topic" "pipeline_notifications" {
  name = "${var.project_name}-pipeline-notifications"
}

# CloudWatch 이벤트 규칙
resource "aws_cloudwatch_event_rule" "pipeline_events" {
  name        = "${var.project_name}-pipeline-events"
  description = "파이프라인 상태 변경 감지"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.pipeline.name]
    }
  })
}

# 이벤트 대상 설정
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.pipeline_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.pipeline_notifications.arn
}