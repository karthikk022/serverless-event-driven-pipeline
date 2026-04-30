# Core Infrastructure Outputs
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# S3 Outputs
output "image_bucket_name" {
  description = "Name of the image upload S3 bucket"
  value       = module.s3.image_bucket_name
}

output "image_bucket_arn" {
  description = "ARN of the image upload S3 bucket"
  value       = module.s3.image_bucket_arn
}

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb.table_arn
}

# API Gateway Outputs
output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = module.api_gateway.api_id
}

output "api_gateway_url" {
  description = "URL of the API Gateway REST API"
  value       = module.api_gateway.api_url
}

output "api_gateway_stage" {
  description = "API Gateway deployment stage name"
  value       = module.api_gateway.stage_name
}

# EventBridge Outputs
output "event_bus_name" {
  description = "Name of the EventBridge custom event bus"
  value       = module.eventbridge.event_bus_name
}

output "event_bus_arn" {
  description = "ARN of the EventBridge custom event bus"
  value       = module.eventbridge.event_bus_arn
}

# Step Functions Outputs
output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.step_functions.state_machine_arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = module.step_functions.state_machine_name
}

# Lambda Outputs
output "lambda_functions" {
  description = "Map of Lambda function names"
  value = {
    s3_processor           = module.lambda.s3_processor_name
    dynamodb_processor     = module.lambda.dynamodb_processor_name
    eventbridge_processor  = module.lambda.eventbridge_processor_name
    api_handler           = module.lambda.api_handler_name
    step_validate         = module.lambda.step_validate_name
    step_transform        = module.lambda.step_transform_name
    step_enrich           = module.lambda.step_enrich_name
    step_notify           = module.lambda.step_notify_name
    step_error_handler    = module.lambda.step_error_handler_name
    dlq_handler           = module.lambda.dlq_name
  }
}

# CloudWatch Outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.eventbridge.sns_topic_arn
}

# X-Ray
output "xray_sampling_rule_name" {
  description = "Name of the X-Ray sampling rule"
  value       = module.xray.sampling_rule_name
}
