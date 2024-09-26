output "lambda_function_arn" {
  value = aws_lambda_function.user_profile_lambda.arn
}
output "api_endpoint" {
  value = "${aws_api_gateway_rest_api.this_api.execution_arn}/prod"
}

output "lambda_layer_arn" {
  value = aws_lambda_layer_version.lambda_layer.arn
}
