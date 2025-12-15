output "api_endpoint" {
  description = "API Gateway endpoint URL - use this to test the application"
  value       = module.api_gateway.api_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL - push Docker images here"
  value       = module.ecr.repository_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.function_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs where Lambda runs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "test_command" {
  description = "Command to test the deployed application"
  value       = "curl ${module.api_gateway.api_endpoint}"
}
