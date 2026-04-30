output "sampling_rule_name" {
  value = aws_xray_sampling_rule.pipeline.rule_name
}

output "group_name" {
  value = aws_xray_group.pipeline.group_name
}