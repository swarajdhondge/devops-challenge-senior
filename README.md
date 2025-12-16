# SimpleTimeService

A serverless microservice that returns the current UTC timestamp and visitor's IP address.

**Live Demo Response:**
```json
{
  "timestamp": "2025-12-15T22:48:16.146876+00:00",
  "ip": "67.185.192.154"
}
```

---

## Task 1: Docker - Build and Run the Container

### Option A: Pull from DockerHub (Recommended)

The easiest way to test the application:

```bash
docker pull swarajdhondge/sts:latest
docker run -p 8080:8080 swarajdhondge/sts:latest
curl http://localhost:8080/
```

### Option B: Build Locally

Build the container from source:

```bash
cd app
docker build -t sts:latest .
docker run -p 8080:8080 sts:latest
curl http://localhost:8080/
```

**Expected Response:**
```json
{"timestamp":"2025-12-15T10:30:00.123456+00:00","ip":"172.17.0.1"}
```

---

## Task 2: Terraform - Deploy to AWS

### Prerequisites

- **AWS CLI** installed and configured
- **Terraform** >= 1.6.0
- **Docker** installed and running
- AWS account with appropriate permissions

### Option A: Direct Terraform Commands (As per requirements)

This is the standard approach mentioned in the challenge requirements:

```bash
# Configure AWS credentials (one-time setup)
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region (us-east-1)

# Deploy infrastructure
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
```

That's it! Terraform will:
1. Create VPC with public/private subnets, NAT Gateway, Internet Gateway
2. Create private ECR repository
3. Build and push Docker image to ECR automatically
4. Deploy Lambda function in private subnets
5. Create API Gateway

After deployment completes, you'll see the API URL:
```
api_endpoint = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/"
```

**Test the deployed API:**
```bash
curl https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/
```

**Cleanup:**
```bash
terraform destroy
```

### Option B: Using Helper Script (For SSO/Temporary Credentials)

If you're using AWS SSO or temporary credentials that don't work with direct Terraform commands:

```bash
# Login with SSO
aws sso login --profile your-profile

# Deploy using helper script
python scripts/run.py init
python scripts/run.py plan
python scripts/run.py apply

# Cleanup
python scripts/run.py destroy
```

The helper script automatically exports AWS credentials for Terraform.

---

## Extra Credit: CI/CD with GitHub Actions

### Setup Instructions

1. **Fork this repository** to your GitHub account

2. **Add GitHub Secrets** (Settings → Secrets and variables → Actions):

| Secret | Description | How to Get |
|--------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | From AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | From AWS IAM Console |
| `DOCKERHUB_USERNAME` | Your DockerHub username | Your DockerHub account |
| `DOCKERHUB_TOKEN` | DockerHub access token | DockerHub → Account Settings → Security |

3. **Add GitHub Variables** (Settings → Secrets and variables → Actions → Variables):

| Variable | Value |
|----------|-------|
| `AWS_REGION` | `us-east-1` |

### Available Workflows

#### 1. Deploy Infrastructure (`deploy.yml`)
- **Trigger:** Push to `main` branch OR manual trigger
- **What it does:** Runs `terraform init`, `terraform plan`, `terraform apply`
- **Output:** Displays API endpoint URL

#### 2. Destroy Infrastructure (`destroy.yml`)
- **Trigger:** Manual only (Actions → Destroy Infrastructure → Run workflow)
- **Safety:** Requires typing "destroy" to confirm
- **What it does:** Runs `terraform destroy` to remove all AWS resources

#### 3. Build and Push Docker Image (`docker-build-push.yml`)
- **Trigger:** Push to `main` (when app files change) OR manual trigger
- **What it does:** Builds and pushes image to DockerHub for Task 1 testing

---

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│          API Gateway (HTTP)             │
│  https://xxx.execute-api.us-east-1...   │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│                   VPC                        │
│  ┌────────────────────────────────────────┐ │
│  │      Private Subnets (2 AZs)           │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │   Lambda Function                │  │ │
│  │  │   - FastAPI + Mangum             │  │ │
│  │  │   - Python 3.12 Container        │  │ │
│  │  │   - Pulls from ECR Private       │  │ │
│  │  └──────────────────────────────────┘  │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │      Public Subnets (2 AZs)            │ │
│  │  - NAT Gateway                         │ │
│  │  - Internet Gateway                    │ │
│  └────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

### Components

| Component | Purpose |
|-----------|---------|
| **API Gateway** | HTTP API endpoint with CORS support |
| **Lambda** | Serverless compute running FastAPI in container |
| **VPC** | Network isolation with public/private subnets |
| **NAT Gateway** | Allows Lambda in private subnets to access internet |
| **ECR Private** | Container registry for Lambda images |
| **CloudWatch** | Logs for Lambda and API Gateway |

---

## Project Structure

```
particle41/
├── app/
│   ├── Dockerfile              # For local testing (Task 1)
│   ├── Dockerfile.lambda       # For AWS Lambda deployment (Task 2)
│   ├── main.py                 # FastAPI application
│   └── requirements.txt        # Python dependencies
├── terraform/
│   ├── envs/dev/               # Development environment
│   │   ├── main.tf             # Root module
│   │   ├── variables.tf        # Variable definitions
│   │   ├── terraform.tfvars    # Default values
│   │   ├── outputs.tf          # Output definitions
│   │   └── providers.tf        # Provider configuration
│   ├── modules/
│   │   ├── api_gateway/        # API Gateway module
│   │   ├── ecr/                # ECR + Docker build/push
│   │   ├── lambda/             # Lambda function module
│   │   └── vpc/                # VPC networking module
│   └── bootstrap/              # S3 backend setup (optional)
├── scripts/
│   └── run.py                  # Helper for SSO credentials
└── .github/workflows/
    ├── deploy.yml              # Deploy infrastructure
    ├── destroy.yml             # Destroy infrastructure
    └── docker-build-push.yml   # Build and push to DockerHub
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Returns timestamp and visitor IP |
| `GET` | `/docs` | Swagger UI documentation |
| `GET` | `/redoc` | ReDoc documentation |

---

## Development

### Run Locally Without Docker

```bash
cd app
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
```

### Environment Variables

No environment variables required - the application works out of the box.

---

## Troubleshooting

### Issue: `terraform apply` fails with "No valid credential sources"

**Solution:** Make sure you've run `aws configure` and entered your credentials, or use the helper script:
```bash
python scripts/run.py apply
```

### Issue: Lambda can't pull ECR image

**Solution:** The ECR module automatically builds and pushes the image during `terraform apply`. If it fails, check:
- Docker is running
- AWS credentials have ECR permissions
- Run `docker ps` to verify Docker is accessible

### Issue: API Gateway returns 5xx errors

**Solution:** Check Lambda logs:
```bash
aws logs tail /aws/lambda/prtcl-dev-lambda-function --follow
```

---

## Cost Estimate

Running this infrastructure will incur AWS costs:

| Service | Estimated Cost |
|---------|----------------|
| Lambda | ~$0.20/million requests + compute time |
| API Gateway | ~$1.00/million requests |
| NAT Gateway | ~$0.045/hour (~$32/month) |
| VPC, Subnets, IGW | Free |
| ECR Storage | ~$0.10/GB/month |

**Total:** ~$35-40/month if left running. **Remember to run `terraform destroy` when done!**

---

## License

This project is created for the Particle41 DevOps Team Challenge.

---

## Author

Created as part of the Particle41 DevOps Challenge assessment.
