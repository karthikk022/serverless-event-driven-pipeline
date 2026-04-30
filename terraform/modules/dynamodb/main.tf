resource "aws_dynamodb_table" "events" {
  name           = "${var.project_name}-events-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    enabled        = true
    attribute_name = "ttl"
  }

  tags = {
    Name = "${var.project_name}-events-${var.environment}"
  }
}

resource "aws_dynamodb_table" "pipeline_metadata" {
  name         = "${var.project_name}-metadata-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pipelineId"

  attribute {
    name = "pipelineId"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-metadata-${var.environment}"
  }
}
