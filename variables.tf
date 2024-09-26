####################################################
# Variables with Defaults
####################################################
variable "env" {
  type        = string
  description = "Name of the environment this infrastructure is for"
  default     = "prod"
}

variable "region" {
  type        = string
  description = "AWS region to deploy the infrastructure"
  default     = "us-east-1"

}

variable "lambda_layer_bucket_name" {
  type        = string
  description = "Name of the S3 bucket where the Lambda layer zip file is stored"
  default     = "lambda-terraform-bz"

}
variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "user-profile"

}

variable "lambda_layer_zip_path" {
  type    = string
  default = "./lambda-layer.zip"
}

variable "timeout" {
  type        = number
  description = "Timeout for Lambda Task"
  default     = 15
}

variable "memory_size" {
  type        = number
  description = "Memory for Lambda Task"
  default     = 128
}

variable "logging_level" {
  type        = string
  description = "Level of logging required for this Lambda function"
  default     = "DEBUG"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.logging_level)
    error_message = "Valid values for logging_level are (DEBUG, INFO, WARNING, ERROR, CRITICAL)"
  }
}
