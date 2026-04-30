variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_s3_processor_arn" {
  description = "ARN of the S3 processor Lambda function"
  type        = string
}
