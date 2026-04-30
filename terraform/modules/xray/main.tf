# X-Ray Module - Distributed tracing configuration

resource "aws_xray_sampling_rule" "pipeline" {
  rule_name      = "${var.project_name}-rule-${var.environment}"
  priority       = 1000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.5
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  attributes = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_xray_group" "pipeline" {
  group_name        = "${var.project_name}-group-${var.environment}"
  filter_expression = "annotation.Project = \"${var.project_name}\""
}
