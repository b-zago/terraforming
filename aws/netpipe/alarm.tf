resource "aws_cloudwatch_metric_alarm" "api_gateway_burst_alarm" {
  alarm_name          = "netpipe-api-gateway-burst-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  evaluation_periods  = 2
  period              = 60
  threshold           = 20
  statistic           = "Sum"
  alarm_description   = "Alarm on unexpected burst traffic"

  alarm_actions             = [aws_sns_topic.api_alerts.arn]
  insufficient_data_actions = []

  dimensions = {
    ApiId = aws_apigatewayv2_api.gateway_http_api.id
    Stage = aws_apigatewayv2_stage.api_stage.name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_long_alarm" {
  alarm_name          = "netpipe-api-gateway-long-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  evaluation_periods  = 1
  period              = 3600
  threshold           = 100
  statistic           = "Sum"
  alarm_description   = "Alarm on unexpected long-term traffic"

  alarm_actions             = [aws_sns_topic.api_alerts.arn]
  insufficient_data_actions = []

  dimensions = {
    ApiId = aws_apigatewayv2_api.gateway_http_api.id
    Stage = aws_apigatewayv2_stage.api_stage.name
  }
}

resource "aws_sns_topic" "api_alerts" {
  name = "netpipe-api-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.api_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
