# Lambda Module - Creates all Lambda functions for the serverless pipeline

data "archive_file" "s3_processor" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/s3-processor/index.py"
  output_path = "${path.module}/../../../src/lambda/s3-processor/s3-processor.zip"
}

data "archive_file" "dynamodb_processor" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/dynamodb-stream-processor/index.py"
  output_path = "${path.module}/../../../src/lambda/dynamodb-stream-processor/dynamodb-processor.zip"
}

data "archive_file" "eventbridge_processor" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/eventbridge-processor/index.py"
  output_path = "${path.module}/../../../src/lambda/eventbridge-processor/eventbridge-processor.zip"
}

data "archive_file" "api_handler" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/api-handler/index.py"
  output_path = "${path.module}/../../../src/lambda/api-handler/api-handler.zip"
}

data "archive_file" "step_validate" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/step-functions-activities/validate.py"
  output_path = "${path.module}/../../../src/lambda/step-functions-activities/validate.zip"
}

data "archive_file" "step_transform" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/step-functions-activities/transform.py"
  output_path = "${path.module}/../../../src/lambda/step-functions-activities/transform.zip"
}

data "archive_file" "step_enrich" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/step-functions-activities/enrich.py"
  output_path = "${path.module}/../../../src/lambda/step-functions-activities/enrich.zip"
}

data "archive_file" "step_notify" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/step-functions-activities/notify.py"
  output_path = "${path.module}/../../../src/lambda/step-functions-activities/notify.zip"
}

data "archive_file" "step_error_handler" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/step-functions-activities/error_handler.py"
  output_path = "${path.module}/../../../src/lambda/step-functions-activities/error_handler.zip"
}

data "archive_file" "dlq_handler" {
  type        = "zip"
  source_file = "${path.module}/../../../src/lambda/dlq-handler/index.py"
  output_path = "${path.module}/../../../src/lambda/dlq-handler/dlq-handler.zip"
}

locals {
  common_lambda_config = {
    runtime       = var.lambda_runtime
    memory_size   = var.lambda_memory_size
    timeout       = var.lambda_timeout
    role          = var.lambda_exec_role_arn
    tracing_config = var.enable_xray ? "Active" : "PassThrough"
  }
}

# S3 Image Processor Lambda
resource "aws_lambda_function" "s3_processor" {
  function_name = "${var.project_name}-s3-processor-${var.environment}"
  handler       = "index.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = 512
  timeout       = 60
  role          = local.common_lambda_config.role
  filename      = data.archive_file.s3_processor.output_path
  source_code_hash = data.archive_file.s3_processor.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE    = var.dynamodb_table_name
      PROCESSED_BUCKET  = "${var.project_name}-processed-${var.environment}"
      EVENT_BUS_NAME    = var.eventbridge_bus_name
      STAGE             = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }

  tags = {
    Name = "S3 Image Processor"
  }
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.image_bucket_arn
}

# DynamoDB Stream Processor Lambda
resource "aws_lambda_function" "dynamodb_processor" {
  function_name = "${var.project_name}-dynamodb-processor-${var.environment}"
  handler       = "index.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = local.common_lambda_config.memory_size
  timeout       = local.common_lambda_config.timeout
  role          = local.common_lambda_config.role
  filename      = data.archive_file.dynamodb_processor.output_path
  source_code_hash = data.archive_file.dynamodb_processor.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE    = var.dynamodb_table_name
      EVENT_BUS_NAME    = var.eventbridge_bus_name
      STAGE             = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }

  tags = {
    Name = "DynamoDB Stream Processor"
  }
}

# DynamoDB Stream Event Source Mapping
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = var.dynamodb_stream_arn
  function_name     = aws_lambda_function.dynamodb_processor.arn
  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true

  filter {
    pattern = jsonencode({
      eventName = ["INSERT", "MODIFY"]
    })
  }
}

# EventBridge Target Lambda
resource "aws_lambda_function" "eventbridge_processor" {
  function_name = "${var.project_name}-eventbridge-processor-${var.environment}"
  handler       = "index.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = local.common_lambda_config.memory_size
  timeout       = local.common_lambda_config.timeout
  role          = local.common_lambda_config.role
  filename      = data.archive_file.eventbridge_processor.output_path
  source_code_hash = data.archive_file.eventbridge_processor.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE    = var.dynamodb_table_name
      EVENT_BUS_NAME    = var.eventbridge_bus_name
      STAGE             = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }

  tags = {
    Name = "EventBridge Processor"
  }
}

# API Handler Lambda (Node.js)
resource "aws_lambda_function" "api_handler" {
  function_name = "${var.project_name}-api-handler-${var.environment}"
  handler       = "index.handler"
  runtime       = var.lambda_node_runtime
  memory_size   = 256
  timeout       = 10
  role          = local.common_lambda_config.role
  filename      = data.archive_file.api_handler.output_path
  source_code_hash = data.archive_file.api_handler.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE    = var.dynamodb_table_name
      IMAGE_BUCKET      = var.image_bucket_name
      EVENT_BUS_NAME    = var.eventbridge_bus_name
      STEP_FUNCTION_ARN = var.step_functions_arn
      STAGE             = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }

  tags = {
    Name = "API Gateway Handler"
  }
}

# Step Functions Activity Lambdas
resource "aws_lambda_function" "step_validate" {
  function_name = "${var.project_name}-step-validate-${var.environment}"
  handler       = "validate.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = 128
  timeout       = 10
  role          = local.common_lambda_config.role
  filename      = data.archive_file.step_validate.output_path
  source_code_hash = data.archive_file.step_validate.output_base64sha256

  environment {
    variables = {
      STAGE = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }
}

resource "aws_lambda_function" "step_transform" {
  function_name = "${var.project_name}-step-transform-${var.environment}"
  handler       = "transform.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = 256
  timeout       = 30
  role          = local.common_lambda_config.role
  filename      = data.archive_file.step_transform.output_path
  source_code_hash = data.archive_file.step_transform.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      STAGE          = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }
}

resource "aws_lambda_function" "step_enrich" {
  function_name = "${var.project_name}-step-enrich-${var.environment}"
  handler       = "enrich.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = 256
  timeout       = 30
  role          = local.common_lambda_config.role
  filename      = data.archive_file.step_enrich.output_path
  source_code_hash = data.archive_file.step_enrich.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      STAGE          = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }
}

resource "aws_lambda_function" "step_notify" {
  function_name = "${var.project_name}-step-notify-${var.environment}"
  handler       = "notify.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = 128
  timeout       = 10
  role          = local.common_lambda_config.role
  filename      = data.archive_file.step_notify.output_path
  source_code_hash = data.archive_file.step_notify.output_base64sha256

  environment {
    variables = {
      STAGE = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }
}

resource "aws_lambda_function" "step_error_handler" {
  function_name = "${var.project_name}-step-error-handler-${var.environment}"
  handler       = "error_handler.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = 128
  timeout       = 10
  role          = local.common_lambda_config.role
  filename      = data.archive_file.step_error_handler.output_path
  source_code_hash = data.archive_file.step_error_handler.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      STAGE          = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }
}

# DLQ Handler Lambda
resource "aws_lambda_function" "dlq_handler" {
  function_name = "${var.project_name}-dlq-handler-${var.environment}"
  handler       = "index.handler"
  runtime       = local.common_lambda_config.runtime
  memory_size   = 128
  timeout       = 30
  role          = local.common_lambda_config.role
  filename      = data.archive_file.dlq_handler.output_path
  source_code_hash = data.archive_file.dlq_handler.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
      STAGE          = var.environment
    }
  }

  tracing_config {
    mode = local.common_lambda_config.tracing_config
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

# SQS DLQ for failed Lambda invocations
resource "aws_sqs_queue" "lambda_dlq" {
  name = "${var.project_name}-lambda-dlq-${var.environment}"

  message_retention_seconds = 1209600  # 14 days
  visibility_timeout_seconds = 300

  tags = {
    Name = "Lambda DLQ"
  }
}

resource "aws_sqs_queue" "step_functions_dlq" {
  name = "${var.project_name}-stepfunctions-dlq-${var.environment}"

  message_retention_seconds = 1209600
  visibility_timeout_seconds = 300

  tags = {
    Name = "Step Functions DLQ"
  }
}
