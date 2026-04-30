# CloudWatch Module - Dashboards, Alarms, and Log Groups

resource "aws_cloudwatch_dashboard" "pipeline" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Invocations"
          region = data.aws_region.current.name
          metrics = [
            for name in values(var.lambda_functions) : [
              "AWS/Lambda", "Invocations", "FunctionName", name, { stat = "Sum", period = 60 }
            ]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Errors"
          region = data.aws_region.current.name
          metrics = [
            for name in values(var.lambda_functions) : [
              "AWS/Lambda", "Errors", "FunctionName", name, { stat = "Sum", period = 60 }
            ]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Duration (p99)"
          region = data.aws_region.current.name
          metrics = [
            for name in values(var.lambda_functions) : [
              "AWS/Lambda", "Duration", "FunctionName", name, { stat = "p99", period = 60 }
            ]
          ]
          period = 60
          stat   = "p99"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Step Functions Executions"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/States", "ExecutionsStarted", "StateMachineArn", var.step_functions_arn, { stat = "Sum", period = 60 }],
            [".", "ExecutionsSucceeded", ".", ".", { stat = "Sum", period = 60 }],
            [".", "ExecutionsFailed", ".", ".", { stat = "Sum", period = 60 }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "Recent Pipeline Events"
          region = data.aws_region.current.name
          query  = "SOURCE '/aws/lambda/${var.project_name}-' | fields @timestamp, @message | sort @timestamp desc | limit 100"
        }
      }
    ]
  })
}

data "aws_region" "current" {}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.lambda_functions

  alarm_name          = "${var.project_name}-lambda-errors-${each.value}-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda error rate exceeded threshold"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = var.lambda_functions

  alarm_name          = "${var.project_name}-lambda-duration-${each.value}-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "p99"
  threshold           = 10000  # 10 seconds
  alarm_description   = "Lambda duration exceeded threshold"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "step_functions_failures" {
  alarm_name          = "${var.project_name}-stepfunctions-failures-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Step Functions execution failed"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    StateMachineArn = var.step_functions_arn
  }
}
