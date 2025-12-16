# SimpleTimeService

A serverless microservice that returns the current UTC timestamp and visitor's IP address.

Created for the Particle41 DevOps Challenge.

## Prerequisites

### Required Tools

- **AWS CLI (v2)** - [Installation Guide](https://aws.amazon.com/cli/)
- **Terraform (>= 1.6.0)** - [Download](https://terraform.io/downloads)
- **Docker** - [Get Docker](https://docs.docker.com/get-docker/)
- **Git** - [Download](https://git-scm.com/downloads)
- **Python 3.8+** - [Download](https://www.python.org/downloads/) (Required for Option B and Option C only)

**Note:** Python helper scripts (`run.py`, `setup.py`) use only standard library - no pip packages needed.

### AWS Credentials Setup

Configure your AWS credentials before deploying:

```bash
aws configure
```

You'll be prompted to enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1`
- Default output format: `json`

---

## Task 1: Docker

Build and run the containerized application.

### Option A: Pull from DockerHub (Recommended)

```bash
docker pull swarajdhondge/sts:latest
docker run -p 8080:8080 swarajdhondge/sts:latest
curl http://localhost:8080/
```

### Option B: Build Locally

```bash
git clone https://github.com/swarajdhondge/devops-challenge-senior.git
cd devops-challenge-senior/app
docker build -t sts:latest .
docker run -p 8080:8080 sts:latest
curl http://localhost:8080/
```

**Expected Response:**

```json
{"timestamp":"2025-12-16T10:30:00.123456+00:00","ip":"172.18.0.2"}
```

**Note:** The application runs as a non-root user (`appuser`) inside the container.

---

## Task 2: Terraform Deployment

Deploy the serverless infrastructure to AWS.

### Option A: Direct Commands (Recommended)

This is the standard approach as specified in the challenge requirements:

```bash
# Clone the repository
git clone https://github.com/swarajdhondge/devops-challenge-senior.git
cd devops-challenge-senior/terraform/envs/dev

# Deploy infrastructure
terraform init
terraform plan
terraform apply -auto-approve
```

**What gets created:**
- VPC with 2 public and 2 private subnets
- NAT Gateway and Internet Gateway
- Private ECR repository
- Lambda function (container-based, in private subnets)
- API Gateway (HTTP API)
- CloudWatch Logs

**Docker image is built and pushed automatically** during `terraform apply`.

**Test the deployed API:**

```bash
curl $(terraform output -raw api_endpoint)
```

**Cleanup:**

```bash
terraform destroy -auto-approve
```

---

### Option B: Using Helper Script (For SSO Users)

If you're using AWS SSO or temporary credentials:

```bash
# Clone and navigate
git clone https://github.com/swarajdhondge/devops-challenge-senior.git
cd devops-challenge-senior

# Deploy
python scripts/run.py init
python scripts/run.py plan
python scripts/run.py apply

# Test
curl $(cd terraform/envs/dev && terraform output -raw api_endpoint)

# Cleanup
python scripts/run.py destroy
```

The helper script automatically exports AWS credentials for Terraform.

---

### Option C: Production Setup (Remote State)

For production environments with S3 remote state and DynamoDB locking:

```bash
# Clone repository
git clone https://github.com/swarajdhondge/devops-challenge-senior.git
cd devops-challenge-senior

# Step 1: Generate backend configuration
python scripts/setup.py dev

# Step 2: Create S3 bucket and DynamoDB table
cd terraform/bootstrap
terraform init
terraform apply -auto-approve

# Step 3: Configure remote backend
cd ../envs/dev
copy backend-remote.tf.example backend.tf   # Windows
# cp backend-remote.tf.example backend.tf   # Linux/Mac

# Step 4: Initialize with remote state
terraform init -backend-config=backend.hcl

# Step 5: Deploy infrastructure
terraform plan
terraform apply -auto-approve

# Test
curl $(terraform output -raw api_endpoint)
```

**Cleanup (reverse order):**

```bash
# Destroy infrastructure
cd terraform/envs/dev
terraform destroy -auto-approve

# Destroy bootstrap resources
cd ../../bootstrap
terraform destroy -auto-approve
```

---

## Extra Credit: CI/CD with GitHub Actions

Automated deployment pipelines using GitHub Actions.

### Setup Instructions

1. **Fork this repository** to your GitHub account

2. **Add GitHub Secrets** (Settings → Secrets and variables → Actions → New repository secret):

| Secret | Description | How to Get |
|--------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key | AWS Console → IAM → Users → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key | AWS Console → IAM → Users → Security credentials |
| `DOCKERHUB_USERNAME` | DockerHub username | Your DockerHub account |
| `DOCKERHUB_TOKEN` | DockerHub access token | DockerHub → Account Settings → Security → New Access Token |

3. **Add GitHub Variables** (Settings → Secrets and variables → Actions → Variables → New repository variable):

| Variable | Value |
|----------|-------|
| `AWS_REGION` | `us-east-1` |

### Available Workflows

| Workflow | File | Trigger | Description |
|----------|------|---------|-------------|
| **Infrastructure - Deploy** | `deploy.yml` | Manual (workflow_dispatch) | Deploys infrastructure using Terraform |
| **Infrastructure - Destroy** | `destroy.yml` | Manual (workflow_dispatch) | Destroys infrastructure (requires typing "destroy") |
| **Docker - Build & Push** | `docker.yml` | Push to `app/**` or Manual | Builds and pushes image to DockerHub |

**To trigger manually:**
1. Go to **Actions** tab in your repository
2. Select the workflow
3. Click **Run workflow**
4. For destroy: type `destroy` in the confirmation field

---

## Architecture

```
Client
  |
  v
API Gateway (HTTPS)
  |
  v
Lambda Function (Private Subnet)
  - FastAPI + Mangum
  - Python 3.12 Container
  - Pulls from ECR Private
  |
  v
NAT Gateway (Internet Access)
```

### Components

| Component | Purpose |
|-----------|---------|
| **VPC** | Network isolation with 2 public and 2 private subnets across 2 AZs |
| **Lambda** | Serverless compute running FastAPI in a container |
| **API Gateway** | HTTP API endpoint with CORS support |
| **ECR Private** | Container registry for Lambda images |
| **NAT Gateway** | Allows Lambda in private subnets to access internet |
| **CloudWatch** | Logs for Lambda and API Gateway |

---

## Project Structure

```
.
├── app/
│   ├── Dockerfile          # For docker run (Task 1)
│   ├── Dockerfile.lambda   # For AWS Lambda (Task 2)
│   ├── main.py             # FastAPI application
│   └── requirements.txt    # Python dependencies
├── terraform/
│   ├── envs/dev/           # Run terraform commands from here
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── outputs.tf
│   │   └── providers.tf
│   ├── modules/
│   │   ├── vpc/            # VPC networking
│   │   ├── lambda/         # Lambda function
│   │   ├── api_gateway/    # API Gateway
│   │   └── ecr/            # ECR + Docker build/push
│   └── bootstrap/          # S3 + DynamoDB for remote state (optional)
├── scripts/
│   ├── run.py              # Helper for SSO credentials
│   └── setup.py            # Remote backend setup
└── .github/workflows/      # CI/CD pipelines
    ├── deploy.yml
    ├── destroy.yml
    └── docker.yml
```

---

## Configuration

All configuration is in [`terraform/envs/dev/terraform.tfvars`](terraform/envs/dev/terraform.tfvars):

```hcl
name_prefix = "prtcl"
aws_region  = "us-east-1"
project     = "sts"
environment = "dev"
vpc_cidr    = "10.0.0.0/16"

lambda_timeout = 30
lambda_memory  = 512
```

**No environment variables required** - everything is configured via Terraform variables.

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Returns timestamp and visitor IP |
| `GET` | `/docs` | Swagger UI documentation |
| `GET` | `/redoc` | ReDoc documentation |

---

## Troubleshooting

### Issue: `terraform apply` fails with "No valid credential sources"

**Solution:** Run `aws configure` and enter your credentials, or use the helper script:

```bash
python scripts/run.py apply
```

### Issue: Lambda can't pull ECR image

**Solution:** The ECR module automatically builds and pushes the image. Verify:
- Docker is running: `docker ps`
- AWS credentials have ECR permissions

### Issue: API Gateway returns 5xx errors

**Solution:** Check Lambda logs:

```bash
aws logs tail /aws/lambda/prtcl-dev-lambda-function --follow
```

---

## Cleanup

Always destroy resources after testing to avoid AWS charges:

```bash
# Local state (Option A or B)
cd terraform/envs/dev
terraform destroy -auto-approve

# Remote state (Option C) - destroy in reverse order
cd terraform/envs/dev
terraform destroy -auto-approve
cd ../../bootstrap
terraform destroy -auto-approve
```

---

**Repository:** https://github.com/swarajdhondge/devops-challenge-senior

**Challenge:** Particle41 DevOps Team Challenge
