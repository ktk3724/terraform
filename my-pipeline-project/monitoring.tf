# CloudWatch 대시보드
resource "aws_cloudwatch_dashboard" "pipeline_dashboard" {
  dashboard_name = "${var.project_name}-pipeline-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CodePipeline", "SuccessCount", "PipelineName", aws_codepipeline.pipeline.name],
            ["AWS/CodePipeline", "FailureCount", "PipelineName", aws_codepipeline.pipeline.name]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "파이프라인 실행 상태"
        }
      }
    ]
  })
}

# CloudWatch 알람
resource "aws_cloudwatch_metric_alarm" "pipeline_failure" {
  alarm_name          = "${var.project_name}-pipeline-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailureCount"
  namespace           = "AWS/CodePipeline"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "파이프라인 실패 알림"
  alarm_actions       = [aws_sns_topic.pipeline_notifications.arn]

  dimensions = {
    PipelineName = aws_codepipeline.pipeline.name
  }
}