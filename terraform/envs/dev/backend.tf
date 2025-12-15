terraform {
  backend "s3" {
    bucket         = "sts-tfstate-REPLACE_WITH_ACCOUNT_ID"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "sts-tfstate-lock"
  }
}

