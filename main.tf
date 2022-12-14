terraform {
  required_providers {

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = random_pet.lambda_bucket_name.id
  force_destroy = true
}

data "archive_file" "lambda_rest_api" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-rest"
  output_path = "${path.module}/lambda-rest.zip"
}
resource "aws_s3_object" "lambda_rest_api" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "lambda-rest.zip"
  source = data.archive_file.lambda_rest_api.output_path
  etag   = filemd5(data.archive_file.lambda_rest_api.output_path)
}
resource "aws_lambda_function" "lambda_rest" {
  function_name = "LambdaRest"
  s3_bucket     = aws_s3_bucket.lambda_bucket.id
  s3_key        = aws_s3_object.lambda_rest_api.key
  runtime       = "nodejs14.x"
  handler       = "rest.handler"

  source_code_hash = data.archive_file.lambda_rest_api.output_base64sha256

  role = data.aws_iam_role.lambda_role.arn
  environment {
    variables = {
      DYNAMO_DB_TABLE = var.dynamo_db_table
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_rest" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_rest.function_name}"
  retention_in_days = 30
}
data "aws_iam_role" "lambda_role" {
  name = var.lambda_service_role_name
}


resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id      = aws_apigatewayv2_api.lambda.id
  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "lambda_rest" {
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_uri    = aws_lambda_function.lambda_rest.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get_all" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "GET /items"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_rest.id}"
}
resource "aws_apigatewayv2_route" "get_one_route" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "GET /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_rest.id}"
}
resource "aws_apigatewayv2_route" "post" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "POST /items"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_rest.id}"
}
resource "aws_apigatewayv2_route" "put" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "PUT /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_rest.id}"
}
resource "aws_apigatewayv2_route" "delete" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "DELETE /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_rest.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_rest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
