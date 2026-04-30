# S3 Processor
output "s3_processor_arn" {
  value = aws_lambda_function.s3_processor.arn
}

output "s3_processor_name" {
  value = aws_lambda_function.s3_processor.function_name
}

# DynamoDB Processor
output "dynamodb_processor_arn" {
  value = aws_lambda_function.dynamodb_processor.arn
}

output "dynamodb_processor_name" {
  value = aws_lambda_function.dynamodb_processor.function_name
}

# EventBridge Processor
output "eventbridge_processor_arn" {
  value = aws_lambda_function.eventbridge_processor.arn
}

output "eventbridge_processor_name" {
  value = aws_lambda_function.eventbridge_processor.function_name
}

# API Handler
output "api_handler_arn" {
  value = aws_lambda_function.api_handler.arn
}

output "api_handler_name" {
  value = aws_lambda_function.api_handler.function_name
}

# Step Functions Activities
output "step_validate_arn" {
  value = aws_lambda_function.step_validate.arn
}

output "step_validate_name" {
  value = aws_lambda_function.step_validate.function_name
}

output "step_transform_arn" {
  value = aws_lambda_function.step_transform.arn
}

output "step_transform_name" {
  value = aws_lambda_function.step_transform.function_name
}

output "step_enrich_arn" {
  value = aws_lambda_function.step_enrich.arn
}

output "step_enrich_name" {
  value = aws_lambda_function.step_enrich.function_name
}

output "step_notify_arn" {
  value = aws_lambda_function.step_notify.arn
}

output "step_notify_name" {
  value = aws_lambda_function.step_notify.function_name
}

output "step_error_handler_arn" {
  value = aws_lambda_function.step_error_handler.arn
}

output "step_error_handler_name" {
  value = aws_lambda_function.step_error_handler.function_name
}

# DLQ
output "dlq_arn" {
  value = aws_sqs_queue.lambda_dlq.arn
}

output "dlq_name" {
  value = aws_lambda_function.dlq_handler.function_name
}

output "sqs_dlq_arn" {
  value = aws_sqs_queue.lambda_dlq.arn
}

output "sqs_dlq_url" {
  value = aws_sqs_queue.lambda_dlq.url
}

output "step_functions_dlq_arn" {
  value = aws_sqs_queue.step_functions_dlq.arn
}

output "step_functions_dlq_url" {
  value = aws_sqs_queue.step_functions_dlq.url
}
