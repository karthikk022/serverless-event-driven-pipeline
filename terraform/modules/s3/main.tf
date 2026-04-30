resource "aws_s3_bucket" "images" {
  bucket = "${var.project_name}-images-${var.environment}-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "image_upload" {
  bucket = aws_s3_bucket.images.id

  lambda_function {
    lambda_function_arn = var.lambda_s3_processor_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".jpg"
  }

  lambda_function {
    lambda_function_arn = var.lambda_s3_processor_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".png"
  }
}

resource "aws_s3_bucket" "processed" {
  bucket = "${var.project_name}-processed-${var.environment}-${random_string.suffix.result}"
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "dlq" {
  bucket = "${var.project_name}-dlq-${var.environment}-${random_string.suffix.result}"
}

resource "aws_s3_bucket_lifecycle_configuration" "dlq" {
  bucket = aws_s3_bucket.dlq.id

  rule {
    id     = "expire-old-messages"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}
