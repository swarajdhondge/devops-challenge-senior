# Run this ONCE to create S3 bucket and DynamoDB table for Terraform state/Remote Backend

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# S3 Bucket for Terraform state
resource "aws_s3_bucket" "tfstate" {
  bucket = "sts-tfstate-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = "Terraform State Bucket"
    Project   = "SimpleTimeService"
    ManagedBy = "terraform"
  }
}

# Enable versioning for state file history
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "sts-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform State Lock Table"
    Project   = "SimpleTimeService"
    ManagedBy = "terraform"
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.tfstate.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.tfstate_lock.id
}

output "instructions" {
  description = "Next steps"
  value       = <<-EOT
    Backend resources created successfully!
    
    Update terraform/envs/dev/backend.tf with:
    bucket = "${aws_s3_bucket.tfstate.id}"
    
    Then run:
    cd ../envs/dev
    terraform init
  EOT
}

