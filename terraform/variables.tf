# variables.tf

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod, staging)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing highlights"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "DYNAMODB_TABLE" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "rapidapi_ssm_parameter_arn" {
  description = "ARN of the RapidAPI key stored in SSM Parameter Store"
  type        = string
}

variable "mediaconvert_endpoint" {
  description = "AWS MediaConvert endpoint"
  type        = string
}

variable "mediaconvert_role_arn" {
  description = "ARN of the MediaConvert IAM role"
  type        = string
}

variable "retry_count" {
  description = "Number of retry attempts for failed operations"
  type        = number
  default     = 3
}

variable "retry_delay" {
  description = "Delay in seconds between retry attempts"
  type        = number
  default     = 60
}
