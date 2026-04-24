resource "aws_scheduler_schedule" "monthly_scheduler" {
  name       = "netpipe-reset-limits-scheduler"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "rate(2 minutes)"
  schedule_expression_timezone = "Europe/Warsaw"

  target {
    arn      = module.lambda_monthly.lambda_data.arn
    role_arn = aws_iam_role.scheduler_iam_role.arn

    retry_policy {
      maximum_retry_attempts       = 3
      maximum_event_age_in_seconds = 300
    }
  }


}
