output "api_id" {
  value = aws_api_gateway_rest_api.pipeline.id
}

output "api_url" {
  value = aws_api_gateway_stage.pipeline.invoke_url
}

output "stage_name" {
  value = aws_api_gateway_stage.pipeline.stage_name
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.pipeline.execution_arn
}
