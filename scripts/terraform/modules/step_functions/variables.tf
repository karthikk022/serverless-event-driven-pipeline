variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "step_functions_role_arn" {
  type = string
}

variable "lambda_validate_arn" {
  type = string
}

variable "lambda_transform_arn" {
  type = string
}

variable "lambda_enrich_arn" {
  type = string
}

variable "lambda_notify_arn" {
  type = string
}

variable "lambda_error_handler_arn" {
  type = string
}
