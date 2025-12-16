terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "main" {
  name                 = "${var.name_prefix}-${var.environment}-${var.project}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = var.tags
}

resource "null_resource" "docker_build_push" {
  triggers = {
    dockerfile_hash   = filemd5("${path.root}/../../../app/Dockerfile.lambda")
    main_py_hash      = filemd5("${path.root}/../../../app/main.py")
    requirements_hash = filemd5("${path.root}/../../../app/requirements.txt")
    ecr_repo_url      = aws_ecr_repository.main.repository_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      docker build --platform linux/amd64 --provenance=false -f ${path.root}/../../../app/Dockerfile.lambda -t ${aws_ecr_repository.main.repository_url}:${var.image_tag} ${path.root}/../../../app
      docker push ${aws_ecr_repository.main.repository_url}:${var.image_tag}
    EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [aws_ecr_repository.main]
}
