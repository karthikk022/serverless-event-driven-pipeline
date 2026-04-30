output "event_bus_name" {
  value = aws_cloudwatch_event_bus.pipeline.name
}

output "event_bus_arn" {
  value = aws_cloudwatch_event_bus.pipeline.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.pipeline_alerts.arn
}

output "sns_topic_name" {
  value = aws_sns_topic.pipeline_alerts.name
}
