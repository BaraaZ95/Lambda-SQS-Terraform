provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.0.0"
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
  cloud {
    organization = "Debugging"
    workspaces {
      name = "Lambda-Terraform"
    }
  }
}


resource "aws_iam_role" "lambda_role" {
  name = "lambda_invoke_role_unique"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ],
  })

  inline_policy {
    name = "lambda_sqs_cloudwatch_policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "sqs:SendMessage",
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
          ],
          Resource = aws_sqs_queue.task_queue.arn
        },
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ],
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }
}

resource "aws_cloudwatch_log_group" "sqs_log_group" {
  name              = "/aws/sqs/${aws_sqs_queue.task_queue.name}"
  retention_in_days = 14 # Adjust as needed
}


# New SQS Queue
resource "aws_sqs_queue" "task_queue" {
  name                              = "task-queue"
  delay_seconds                     = 90
  max_message_size                  = 1048
  message_retention_seconds         = 86400
  receive_wait_time_seconds         = 10
  visibility_timeout_seconds        = 15
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Environment = var.env
  }
  lifecycle {
    create_before_destroy = true
    #prevent_destroy       = true
    ignore_changes = [
      kms_master_key_id,
      kms_data_key_reuse_period_seconds,
    ]
  }
}


resource "aws_s3_bucket" "lambda_layer_bucket" {
  bucket        = var.lambda_layer_bucket_name
  force_destroy = true
  lifecycle {
    create_before_destroy = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "lambda_layer_bucket" {
  bucket = aws_s3_bucket.lambda_layer_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "lambda_layer" {
  bucket = aws_s3_bucket.lambda_layer_bucket.id
  key    = "lambda-layer.zip"
  source = "${path.module}/layer/lambda-layer.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "lambda-dependencies-layer"
  s3_bucket  = aws_s3_bucket.lambda_layer_bucket.id
  s3_key     = aws_s3_object.lambda_layer.key

  compatible_runtimes = ["python3.10"]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "user_profile_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  runtime          = "python3.10"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  memory_size      = var.memory_size
  timeout          = var.timeout
  environment {
    variables = {
      ENV           = var.env
      SQS_QUEUE_URL = aws_sqs_queue.task_queue.url
    }
  }
}

# New Lambda function for processing SQS messages
resource "aws_lambda_function" "process_queue_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "process_queue_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.process_queue"
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  runtime          = "python3.10"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  memory_size      = var.memory_size
  timeout          = 15

  environment {
    variables = {
      ENV           = var.env
      SQS_QUEUE_URL = aws_sqs_queue.task_queue.url
    }
  }
}
# Lambda event source mapping
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.task_queue.arn
  function_name    = aws_lambda_function.process_queue_lambda.arn
  batch_size       = 1
}

###############################
# API Gateway
###############################

resource "aws_api_gateway_rest_api" "this_api" {
  name        = "test-api"
  description = "API Gateway for processing user profile. Accepts POST requests to /user/{user_id}"
  # tags        = local.common_tags
}

# User API resources
resource "aws_api_gateway_resource" "this_user_resource" {
  rest_api_id = aws_api_gateway_rest_api.this_api.id
  parent_id   = aws_api_gateway_rest_api.this_api.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_resource" "this_user_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.this_api.id
  parent_id   = aws_api_gateway_resource.this_user_resource.id
  path_part   = "{user_id}"
}

resource "aws_api_gateway_method" "this_user_id_get" {
  rest_api_id          = aws_api_gateway_rest_api.this_api.id
  resource_id          = aws_api_gateway_resource.this_user_id_resource.id
  http_method          = "POST"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.this_request_validator.id
  request_parameters = {
    "method.request.header.type" = true
  }
}

resource "aws_api_gateway_integration" "this_user_integration" {
  rest_api_id             = aws_api_gateway_rest_api.this_api.id
  resource_id             = aws_api_gateway_resource.this_user_id_resource.id
  http_method             = aws_api_gateway_method.this_user_id_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.user_profile_lambda.invoke_arn
  request_parameters = {
    "integration.request.header.type" = "method.request.header.type"
  }
}

# Common resources
resource "aws_api_gateway_integration_response" "user_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.this_api.id
  resource_id = aws_api_gateway_resource.this_user_id_resource.id
  http_method = aws_api_gateway_method.this_user_id_get.http_method
  status_code = "202"

  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_integration.this_user_integration]
}

resource "aws_api_gateway_request_validator" "this_request_validator" {
  rest_api_id                 = aws_api_gateway_rest_api.this_api.id
  name                        = "request-validator"
  validate_request_body       = false
  validate_request_parameters = true
}

resource "aws_api_gateway_deployment" "this_deployment" {
  depends_on = [
  aws_api_gateway_integration.this_user_integration]
  rest_api_id = aws_api_gateway_rest_api.this_api.id
  stage_name  = var.env

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_profile_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this_api.execution_arn}/*/*"
}
