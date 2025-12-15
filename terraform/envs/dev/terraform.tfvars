aws_region  = "us-east-1"
project     = "sts"
environment = "dev"

vpc_cidr = "10.0.0.0/16"

image_tag                 = "latest"
lambda_timeout            = 30
lambda_memory             = 512
lambda_log_retention_days = 7
api_gateway_stage_name    = "$default"

tags = {
  Project     = "SimpleTimeService"
  Environment = "dev"
  ManagedBy   = "terraform"
  Owner       = "DevOps"
  Purpose     = "Particle41 DevOps Challenge"
}

