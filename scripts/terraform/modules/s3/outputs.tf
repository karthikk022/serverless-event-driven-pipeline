output "image_bucket_name" {
  description = "Name of the image upload bucket"
  value       = aws_s3_bucket.images.bucket
}

output "image_bucket_arn" {
  description = "ARN of the image upload bucket"
  value       = aws_s3_bucket.images.arn
}

output "image_bucket_id" {
  description = "ID of the image upload bucket"
  value       = aws_s3_bucket.images.id
}

output "processed_bucket_name" {
  description = "Name of the processed images bucket"
  value       = aws_s3_bucket.processed.bucket
}

output "processed_bucket_arn" {
  description = "ARN of the processed images bucket"
  value       = aws_s3_bucket.processed.arn
}

output "dlq_bucket_name" {
  description = "Name of the DLQ bucket"
  value       = aws_s3_bucket.dlq.bucket
}

output "dlq_bucket_arn" {
  description = "ARN of the DLQ bucket"
  value       = aws_s3_bucket.dlq.arn
}
