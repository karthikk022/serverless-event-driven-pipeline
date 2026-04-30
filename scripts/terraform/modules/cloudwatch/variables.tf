variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_functions" {
  type = map(string)
}

variable "step_functions_arn" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}