variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_event_processor_arn" {
  type = string
}

variable "lambda_dlq_arn" {
  type = string
}

variable "step_functions_arn" {
  type = string
}

variable "eventbridge_role_arn" {
  type = string
}
