# EventBridge Module - Custom event bus, rules, and targets

resource "aws_cloudwatch_event_bus" "pipeline" {
  name = "${var.project_name}-bus-${var.environment}"
}

resource "aws_cloudwatch_event_rule" "image_processed" {
  name           = "${var.project_name}-image-processed-${var.environment}"
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  description    = "Capture image processed events"

  event_pattern = jsonencode({
    source      = ["serverless.pipeline"]
    detail-type = ["ImageProcessed"]
  })
}

resource "aws_cloudwatch_event_rule" "pipeline_triggered" {
  name           = "${var.project_name}-pipeline-triggered-${var.environment}"
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  description    = "Capture pipeline trigger events"

  event_pattern = jsonencode({
    source      = ["serverless.pipeline"]
    detail-type = ["PipelineTriggered", "EventCreated"]
  })
}

resource "aws_cloudwatch_event_rule" "all_events" {
  name           = "${var.project_name}-all-events-${var.environment}"
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  description    = "Catch-all rule for monitoring"

  event_pattern = jsonencode({
    source = ["serverless.pipeline"]
  })
}

# Targets for image_processed rule
resource "aws_cloudwatch_event_target" "image_to_lambda" {
  rule           = aws_cloudwatch_event_rule.image_processed.name
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  target_id      = "EventBridgeProcessor"
  arn            = var.lambda_event_processor_arn
}

resource "aws_cloudwatch_event_target" "image_to_step_functions" {
  rule           = aws_cloudwatch_event_rule.pipeline_triggered.name
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  target_id      = "StepFunctionsPipeline"
  arn            = var.step_functions_arn
  role_arn       = var.eventbridge_role_arn
}

# SNS Topic for notifications
resource "aws_sns_topic" "pipeline_alerts" {
  name = "${var.project_name}-alerts-${var.environment}"

  tags = {
    Name = "Pipeline Alerts"
  }
}

resource "aws_cloudwatch_event_target" "image_to_sns" {
  rule           = aws_cloudwatch_event_rule.all_events.name
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  target_id      = "SNSAlerts"
  arn            = aws_sns_topic.pipeline_alerts.arn
}

# Archive all events for replay capability
resource "aws_cloudwatch_event_archive" "pipeline" {
  name           = "${var.project_name}-archive-${var.environment}"
  event_source_arn = aws_cloudwatch_event_bus.pipeline.arn
  description    = "Archive of all pipeline events"
  retention_days = 7
}
