output "lambda_exec_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_exec.arn
}

output "step_functions_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.step_functions.arn
}

output "eventbridge_role_arn" {
  description = "ARN of the EventBridge execution role"
  value       = aws_iam_role.eventbridge.arn
}

output "api_gateway_cloudwatch_role_arn" {
  description = "ARN of the API Gateway CloudWatch role"
  value       = aws_iam_role.api_gateway_cloudwatch.arn
}
