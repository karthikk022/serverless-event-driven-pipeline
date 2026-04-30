resource "aws_api_gateway_rest_api" "pipeline" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "Serverless Event Pipeline API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  binary_media_types = ["multipart/form-data"]
}

resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.pipeline.id
  parent_id   = aws_api_gateway_rest_api.pipeline.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_resource" "images" {
  rest_api_id = aws_api_gateway_rest_api.pipeline.id
  parent_id   = aws_api_gateway_rest_api.pipeline.root_resource_id
  path_part   = "images"
}

resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.pipeline.id
  parent_id   = aws_api_gateway_resource.images.id
  path_part   = "upload"
}

resource "aws_api_gateway_resource" "pipeline" {
  rest_api_id = aws_api_gateway_rest_api.pipeline.id
  parent_id   = aws_api_gateway_rest_api.pipeline.root_resource_id
  path_part   = "pipeline"
}

resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.pipeline.id
  parent_id   = aws_api_gateway_rest_api.pipeline.root_resource_id
  path_part   = "health"
}

# GET /events - List events
resource "aws_api_gateway_method" "events_get" {
  rest_api_id   = aws_api_gateway_rest_api.pipeline.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "events_get" {
  rest_api_id             = aws_api_gateway_rest_api.pipeline.id
  resource_id             = aws_api_gateway_resource.events.id
  http_method             = aws_api_gateway_method.events_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# POST /events - Create event
resource "aws_api_gateway_method" "events_post" {
  rest_api_id   = aws_api_gateway_rest_api.pipeline.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "events_post" {
  rest_api_id             = aws_api_gateway_rest_api.pipeline.id
  resource_id             = aws_api_gateway_resource.events.id
  http_method             = aws_api_gateway_method.events_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# POST /images/upload - Upload image
resource "aws_api_gateway_method" "upload_post" {
  rest_api_id   = aws_api_gateway_rest_api.pipeline.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "upload_post" {
  rest_api_id             = aws_api_gateway_rest_api.pipeline.id
  resource_id             = aws_api_gateway_resource.upload.id
  http_method             = aws_api_gateway_method.upload_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# POST /pipeline - Trigger pipeline
resource "aws_api_gateway_method" "pipeline_post" {
  rest_api_id   = aws_api_gateway_rest_api.pipeline.id
  resource_id   = aws_api_gateway_resource.pipeline.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "pipeline_post" {
  rest_api_id             = aws_api_gateway_rest_api.pipeline.id
  resource_id             = aws_api_gateway_resource.pipeline.id
  http_method             = aws_api_gateway_method.pipeline_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# GET /health - Health check
resource "aws_api_gateway_method" "health_get" {
  rest_api_id   = aws_api_gateway_rest_api.pipeline.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "health_get" {
  rest_api_id             = aws_api_gateway_rest_api.pipeline.id
  resource_id             = aws_api_gateway_resource.health.id
  http_method             = aws_api_gateway_method.health_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# CORS for all resources
locals {
  methods = [
    { method = aws_api_gateway_method.events_get, resource = aws_api_gateway_resource.events },
    { method = aws_api_gateway_method.events_post, resource = aws_api_gateway_resource.events },
    { method = aws_api_gateway_method.upload_post, resource = aws_api_gateway_resource.upload },
    { method = aws_api_gateway_method.pipeline_post, resource = aws_api_gateway_resource.pipeline },
    { method = aws_api_gateway_method.health_get, resource = aws_api_gateway_resource.health },
  ]
}

resource "aws_api_gateway_method" "cors" {
  for_each = { for idx, m in local.methods : idx => m }

  rest_api_id   = aws_api_gateway_rest_api.pipeline.id
  resource_id   = each.value.resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors" {
  for_each = { for idx, m in local.methods : idx => m }

  rest_api_id = aws_api_gateway_rest_api.pipeline.id
  resource_id = each.value.resource.id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "cors" {
  for_each = { for idx, m in local.methods : idx => m }

  rest_api_id = aws_api_gateway_rest_api.pipeline.id
  resource_id = each.value.resource.id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods"   = true
    "method.response.header.Access-Control-Allow-Origin"    = true
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  for_each = { for idx, m in local.methods : idx => m }

  rest_api_id = aws_api_gateway_rest_api.pipeline.id
  resource_id = each.value.resource.id
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = aws_api_gateway_method_response.cors[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods"   = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"    = "'*'"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_api_handler_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.pipeline.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "pipeline" {
  rest_api_id = aws_api_gateway_rest_api.pipeline.id

  depends_on = [
    aws_api_gateway_integration.events_get,
    aws_api_gateway_integration.events_post,
    aws_api_gateway_integration.upload_post,
    aws_api_gateway_integration.pipeline_post,
    aws_api_gateway_integration.health_get,
    aws_api_gateway_integration_response.cors,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "pipeline" {
  deployment_id = aws_api_gateway_deployment.pipeline.id
  rest_api_id   = aws_api_gateway_rest_api.pipeline.id
  stage_name    = var.environment

  xray_tracing_enabled = true
  tracing_enabled      = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
    })
  }

  depends_on = [aws_api_gateway_account.settings]
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 14
}

resource "aws_api_gateway_account" "settings" {
  cloudwatch_role_arn = var.cloudwatch_role_arn
}
