variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "lambda_exec_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}

variable "step_functions_role_arn" {
  description = "ARN of the Step Functions role"
  type        = string
}

variable "eventbridge_role_arn" {
  description = "ARN of the EventBridge role"
  type        = string
}

variable "image_bucket_name" {
  description = "Name of the image S3 bucket"
  type        = string
}

variable "image_bucket_arn" {
  description = "ARN of the image S3 bucket"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}

variable "dynamodb_stream_arn" {
  description = "ARN of the DynamoDB stream"
  type        = string
}

variable "eventbridge_bus_name" {
  description = "Name of the EventBridge event bus"
  type        = string
}

variable "step_functions_arn" {
  description = "ARN of the Step Functions state machine"
  type        = string
}

variable "lambda_runtime" {
  description = "Python Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_node_runtime" {
  description = "Node.js Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_memory_size" {
  description = "Lambda memory size"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda timeout"
  type        = number
  default     = 30
}

variable "enable_xray" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}
