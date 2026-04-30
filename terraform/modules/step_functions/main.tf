# Step Functions Module - Workflow orchestration

resource "aws_sfn_state_machine" "pipeline" {
  name       = "${var.project_name}-orchestrator-${var.environment}"
  role_arn   = var.step_functions_role_arn
  definition = templatefile("${path.module}/../../../src/step-functions/pipeline-workflow.asl.json", {
    lambda_validate_arn      = var.lambda_validate_arn
    lambda_transform_arn     = var.lambda_transform_arn
    lambda_enrich_arn        = var.lambda_enrich_arn
    lambda_notify_arn        = var.lambda_notify_arn
    lambda_error_handler_arn = var.lambda_error_handler_arn
    event_bus_name           = "${var.project_name}-bus-${var.environment}"
    sns_topic_arn            = "arn:aws:sns:${var.region}:${var.account_id}:${var.project_name}-alerts-${var.environment}"
  })

  tracing_configuration {
    enabled = true
  }

  tags = {
    Name = "Pipeline Orchestrator"
  }
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "/aws/stepfunctions/${var.project_name}-${var.environment}"
  retention_in_days = 14
}
