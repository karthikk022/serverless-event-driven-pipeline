output "table_name" {
  description = "Name of the main DynamoDB table"
  value       = aws_dynamodb_table.events.name
}

output "table_arn" {
  description = "ARN of the main DynamoDB table"
  value       = aws_dynamodb_table.events.arn
}

output "stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = aws_dynamodb_table.events.stream_arn
}

output "metadata_table_name" {
  description = "Name of the metadata DynamoDB table"
  value       = aws_dynamodb_table.pipeline_metadata.name
}

output "metadata_table_arn" {
  description = "ARN of the metadata DynamoDB table"
  value       = aws_dynamodb_table.pipeline_metadata.arn
}
