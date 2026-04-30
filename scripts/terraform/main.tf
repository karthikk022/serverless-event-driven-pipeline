# Serverless Event-Driven Pipeline
# Terraform Root Configuration

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "serverless-event-driven-pipeline"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Module - creates all roles and policies
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  region       = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
}

# S3 Module - image upload bucket with event notifications
module "s3" {
  source = "./modules/s3"

  project_name           = var.project_name
  environment            = var.environment
  lambda_s3_processor_arn = module.lambda.s3_processor_arn
}

# DynamoDB Module - main table with streams
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
}

# Lambda Module - all Lambda functions
module "lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  region       = var.aws_region

  lambda_exec_role_arn     = module.iam.lambda_exec_role_arn
  step_functions_role_arn  = module.iam.step_functions_role_arn
  eventbridge_role_arn     = module.iam.eventbridge_role_arn

  image_bucket_name        = module.s3.image_bucket_name
  image_bucket_arn         = module.s3.image_bucket_arn
  dynamodb_table_name      = module.dynamodb.table_name
  dynamodb_table_arn       = module.dynamodb.table_arn
  dynamodb_stream_arn      = module.dynamodb.stream_arn
  eventbridge_bus_name     = module.eventbridge.event_bus_name
  step_functions_arn       = module.step_functions.state_machine_arn
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name = var.project_name
  environment  = var.environment
  region       = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id

  lambda_api_handler_arn     = module.lambda.api_handler_arn
  lambda_api_handler_name    = module.lambda.api_handler_name
  cloudwatch_role_arn        = module.iam.api_gateway_cloudwatch_role_arn
}

# EventBridge Module
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name = var.project_name
  environment  = var.environment

  lambda_event_processor_arn  = module.lambda.eventbridge_processor_arn
  lambda_dlq_arn             = module.lambda.dlq_arn
  step_functions_arn         = module.step_functions.state_machine_arn
  sns_topic_arn              = module.eventbridge.sns_topic_arn
}

# Step Functions Module
module "step_functions" {
  source = "./modules/step_functions"

  project_name             = var.project_name
  environment              = var.environment
  region                   = var.aws_region
  account_id               = data.aws_caller_identity.current.account_id

  step_functions_role_arn  = module.iam.step_functions_role_arn
  lambda_validate_arn      = module.lambda.step_validate_arn
  lambda_transform_arn       = module.lambda.step_transform_arn
  lambda_enrich_arn        = module.lambda.step_enrich_arn
  lambda_notify_arn        = module.lambda.step_notify_arn
  lambda_error_handler_arn = module.lambda.step_error_handler_arn
}

# X-Ray Module - tracing configuration
module "xray" {
  source = "./modules/xray"

  project_name = var.project_name
  environment  = var.environment
}

# CloudWatch Module - alarms and dashboards
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name = var.project_name
  environment  = var.environment

  lambda_functions = {
    s3_processor           = module.lambda.s3_processor_name
    dynamodb_processor     = module.lambda.dynamodb_processor_name
    eventbridge_processor  = module.lambda.eventbridge_processor_name
    api_handler           = module.lambda.api_handler_name
    step_validate         = module.lambda.step_validate_name
    step_transform        = module.lambda.step_transform_name
    step_enrich           = module.lambda.step_enrich_name
    step_notify           = module.lambda.step_notify_name
  }

  step_functions_arn = module.step_functions.state_machine_arn
  sns_topic_arn      = module.eventbridge.sns_topic_arn
}
