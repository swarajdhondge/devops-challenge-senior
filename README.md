# SimpleTimeService - Particle41 DevOps Challenge

A simple microservice that returns the current timestamp and visitor's IP address, deployed to AWS Lambda with infrastructure as code.

## 1. Project Overview

### What is this project?

SimpleTimeService is a serverless API that responds to GET requests with:

- Current UTC timestamp in ISO format
- Visitor's IP address (extracted from X-Forwarded-For header)

### Technologies Used

- **Python 3.12**: Application runtime
- **FastAPI**: Modern web framework
- **Mangum**: ASGI to Lambda adapter
- **Docker**: Containerization with multi-stage build
- **Terraform**: Infrastructure as Code
- **AWS Lambda**: Serverless compute
- **API Gateway**: HTTP API for public access
- **VPC**: Network isolation with public/private subnets
- **ECR**: Container image registry

### Architecture Overview

The application runs as a containerized Lambda function in private subnets, accessed via API Gateway. Infrastructure is defined in Terraform with modular design.

## 2. Architecture Diagram

```
┌─────────────┐
│   Internet  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│          API Gateway (HTTP API)              │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│                   VPC                        │
│  ┌────────────────────────────────────┐     │
│  │      Public Subnets (2 AZs)        │     │
│  │  ┌──────────┐    ┌──────────┐     │     │
│  │  │   NAT    │    │   IGW    │     │     │
│  │  └──────────┘    └──────────┘     │     │
│  └────────────────────────────────────┘     │
│                   │                         │
│  ┌────────────────────────────────────┐     │
│  │     Private Subnets (2 AZs)        │     │
│  │  ┌──────────────────────────┐     │     │
│  │  │   Lambda Function        │     │     │
│  │  │   (Container Image)       │     │     │
│  │  └──────────────────────────┘     │     │
│  └────────────────────────────────────┘     │
└─────────────────────────────────────────────┘
                   │
                   ▼
            ┌──────────┐
            │   ECR    │
            └──────────┘
```

**Request Flow:**

1. User → API Gateway (public)
2. API Gateway → Lambda (private subnet via VPC)
3. Lambda → Response with timestamp and IP

## 3. Prerequisites

### Required Tools

| Tool      | Version | Installation Link                                                                                 |
| --------- | ------- | ------------------------------------------------------------------------------------------------- |
| AWS CLI   | 2.x     | [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)     |
| Terraform | 1.6+    | [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) |
| Docker    | 24+     | [Install Docker](https://docs.docker.com/get-docker/)                                                |
| Git       | 2.x+    | [Install Git](https://git-scm.com/downloads)                                                         |

### AWS Requirements

- AWS Account with admin access (or appropriate IAM permissions)
- Permissions to create:
  - VPC, Subnets, NAT Gateway, Internet Gateway
  - Lambda functions, IAM roles
  - API Gateway, ECR
  - S3 buckets, DynamoDB tables
  - CloudWatch Log Groups

## 4. Cost Estimate

### Estimated Monthly Cost

| Resource                    | Cost         | Notes                        |
| --------------------------- | ------------ | ---------------------------- |
| NAT Gateway                 | ~$32/month   | Fixed cost (primary expense) |
| Lambda (1M requests, 512MB) | ~$1/month    | Pay per request + compute    |
| API Gateway (1M requests)   | ~$1/month    | HTTP API pricing             |
| ECR Storage (1GB)           | ~$0.10/month | Image storage                |
| CloudWatch Logs             | ~$0.50/month | Log ingestion                |
| S3/DynamoDB (state)         | ~$0.10/month | Terraform state storage      |

**Total: ~$35/month for 1M requests**

**Note:** NAT Gateway is the primary cost. Clean up resources after testing to avoid charges.

## 5. Deployment Instructions

### Step 1: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Key, and region (e.g., us-east-1)
```

Alternatively, use environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2: Bootstrap Remote State (One-time)

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

**Important:** Note the S3 bucket name from the output (it contains your AWS account ID).

### Step 3: Update Backend Configuration

Edit `terraform/envs/dev/backend.tf` and replace `REPLACE_WITH_ACCOUNT_ID` with your AWS account ID from Step 2.

Example: If the bucket name is `sts-tfstate-123456789012`, replace `REPLACE_WITH_ACCOUNT_ID` with `123456789012`.

**Note:** Backend blocks cannot use Terraform interpolation, so this must be done manually.

### Step 4: Build and Push Docker Image

```bash
# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build image
cd app
docker build -t sts:latest .

# Tag and push (replace ACCOUNT_ID with your actual account ID)
docker tag sts:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/sts:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/sts:latest
```

**Note:** You may need to create the ECR repository first, or let Terraform create it in Step 5, then push the image.

### Step 5: Deploy Infrastructure

```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted to create resources.

### Step 6: Test the API

```bash
# Get API Gateway URL from Terraform output
API_ENDPOINT=$(terraform output -raw api_endpoint)

# Test the service
curl $API_ENDPOINT
```

**Expected response:**

```json
{
  "timestamp": "2024-12-14T12:34:56.789012+00:00",
  "ip": "1.2.3.4"
}
```

## 6. Testing

### Local Docker Test

```bash
cd app
docker build -t sts:latest .
docker run -p 8000:8000 sts:latest

# In another terminal
curl http://localhost:8000/
```

### Unit Tests

```bash
cd app
pip install -r requirements.txt
pytest test_main.py -v
```

**Expected output:**

```
test_main.py::test_root_endpoint_returns_200 PASSED
test_main.py::test_root_endpoint_returns_json PASSED
test_main.py::test_timestamp_format PASSED
test_main.py::test_ip_is_string PASSED
```

## 7. Troubleshooting

### Issue: "Backend configuration not found"

**Solution:** Run bootstrap first (Step 2), then update `backend.tf` with your account ID (Step 3).

### Issue: "No such image" when deploying Lambda

**Solution:** Push Docker image to ECR before running terraform apply (Step 4). Alternatively, let Terraform create the ECR repository first, then push the image.

### Issue: "Access Denied" for ECR

**Solution:** Run `aws ecr get-login-password` command and ensure you're authenticated. Check your AWS credentials with `aws sts get-caller-identity`.

### Issue: Lambda timeout or cold start

**Solution:** Lambda in VPC has cold start penalty (~2-3s). First request may be slow. Subsequent requests are faster. If timeouts occur, increase `lambda_timeout` in `terraform.tfvars`.

### Issue: "VPC does not exist"

**Solution:** Ensure terraform apply completed successfully. Check AWS Console for VPC creation. Verify your AWS credentials have VPC creation permissions.

### Issue: Terraform state locked

**Solution:** Another terraform process may be running. Wait for it to complete, or if stuck, use `terraform force-unlock LOCK_ID` (use carefully).

## 8. Cleanup (IMPORTANT - Avoid Charges)

To destroy all resources and avoid charges:

```bash
# Destroy infrastructure
cd terraform/envs/dev
terraform destroy
```

Type `yes` when prompted.

**This will delete:**

- VPC and all networking components (NAT Gateway, subnets, etc.)
- Lambda function
- API Gateway
- ECR repository and images
- CloudWatch Log Groups

**Optional:** Delete ECR images manually if Terraform doesn't remove them:

```bash
aws ecr batch-delete-image --repository-name sts --image-ids imageTag=latest
```

**Optional:** Destroy bootstrap resources (if you want to remove state backend):

```bash
cd terraform/bootstrap
terraform destroy
```

**Cost Warning:** NAT Gateway costs ~$32/month. Always destroy after testing to avoid charges.

## 9. Extra Credit Features

### Remote Terraform Backend (S3 + DynamoDB)

The project includes a remote state backend configuration:

- **S3 Bucket**: Stores Terraform state files

  - Versioning enabled (state history)
  - Encryption at rest (AES256)
  - Public access blocked
- **DynamoDB Table**: State locking

  - Prevents concurrent modifications
  - On-demand billing (minimal cost)

**Benefits:**

- State is stored remotely (not in local files)
- Version history for state changes
- Team collaboration (shared state)
- Disaster recovery (state backup)

### Architecture Decisions

- **Lambda in VPC:** Required by challenge for private subnets
- **Single NAT Gateway:** Cost optimization for dev (not HA)
- **HTTP API Gateway:** Cheaper and simpler than REST API
- **Container Image:** Allows flexibility in dependencies
- **FastAPI + Mangum:** Modern Python framework with Lambda adapter
- **Modular Terraform:** Reusable modules for maintainability

## Project Structure

```
.
├── README.md                    # This file
├── .gitignore                   # Git ignore rules
├── app/
│   ├── main.py                  # FastAPI application
│   ├── Dockerfile               # Multi-stage Docker build
│   ├── requirements.txt         # Python dependencies
│   └── test_main.py             # Unit tests
└── terraform/
    ├── bootstrap/
    │   └── backend-resources.tf # S3 + DynamoDB for state
    ├── envs/
    │   └── dev/
    │       ├── main.tf          # Root module
    │       ├── variables.tf     # Variable definitions
    │       ├── outputs.tf       # Outputs
    │       ├── terraform.tfvars # Variable values
    │       ├── backend.tf       # Remote state config
    │       └── providers.tf     # Provider config
    └── modules/
        ├── vpc/                 # VPC module
        ├── lambda/              # Lambda module
        ├── api_gateway/         # API Gateway module
        └── ecr/                 # ECR module
```

## Security Features

- ✅ Non-root container user (UID 1000)
- ✅ Lambda in private subnets
- ✅ No hardcoded secrets
- ✅ Encrypted Terraform state
- ✅ State locking with DynamoDB
- ✅ Least privilege IAM roles
- ✅ VPC with public/private subnet separation

## License

This project is created for the Particle41 DevOps Challenge.

---

**Built for the Particle41 DevOps Team**
