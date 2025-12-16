variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "prtcl"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
}

variable "lambda_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "api_gateway_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "$default"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
