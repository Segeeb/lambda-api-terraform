provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# Zip the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda function
resource "aws_lambda_function" "hello_world" {
  filename      = "lambda_function.zip"
  function_name = "helloWorld"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# API Gateway
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "helloWorldAPI"
  protocol_type = "HTTP"
}

# Integrate Lambda with API Gateway
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.hello_world.invoke_arn
}

# Define a route (e.g., GET /hello)
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Add this right after your aws_apigatewayv2_route resource
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"  # The default stage name for HTTP APIs
  auto_deploy = true        # Automatically deploy changes
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"
  
  # This covers ALL routes/methods in your API
  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*/*"
  
  # Add these lifecycle rules to prevent conflicts
  lifecycle {
    create_before_destroy = true
    ignore_changes = [statement_id]
  }
}

# Output the API URL
output "api_url" {
  value = aws_apigatewayv2_api.lambda_api.api_endpoint
}