data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  tags = var.tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.project

  tags = var.tags
}

module "lambda" {
  source = "../../modules/lambda"

  project            = var.project
  environment        = var.environment
  image_uri          = "${module.ecr.repository_url}:${var.image_tag}"
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_id  = module.vpc.lambda_security_group_id
  timeout            = var.lambda_timeout
  memory_size        = var.lambda_memory
  log_retention_days = var.lambda_log_retention_days

  tags = var.tags

  depends_on = [module.ecr]
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  project             = var.project
  environment         = var.environment
  lambda_function_arn = module.lambda.function_arn
  lambda_invoke_arn   = module.lambda.invoke_arn
  stage_name          = var.api_gateway_stage_name

  tags = var.tags
}
