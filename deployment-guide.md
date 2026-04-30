# Deployment Guide

## Prerequisites

Before deploying, ensure you have:

- [ ] AWS CLI v2 installed and configured
- [ ] Terraform 1.5+ installed
- [ ] Python 3.11+ installed
- [ ] Node.js 20+ installed
- [ ] AWS account with appropriate permissions

Required AWS permissions:
- IAM: Create roles and policies
- Lambda: Create and update functions
- S3: Create buckets and configure notifications
- DynamoDB: Create tables and streams
- EventBridge: Create event buses and rules
- Step Functions: Create state machines
- API Gateway: Create REST APIs
- CloudWatch: Create dashboards and alarms
- X-Ray: Create sampling rules

## Deployment Steps

### 1. Environment Setup

```bash
# Clone repository
git clone <repository-url>
cd serverless-event-driven-pipeline

# Run setup script
./scripts/setup-local.sh

# Or manually:
npm install
python3 -m venv venv
source venv/bin/activate
pip install -r src/lambda/requirements.txt
```

### 2. AWS Configuration

```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

### 3. Terraform Backend (Optional)

For production, configure remote state:

```hcl
# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "serverless-pipeline/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 4. Deploy Infrastructure

```bash
cd terraform

# Initialize
terraform init

# Plan (review changes)
terraform plan -var="environment=dev" -out=tfplan

# Apply
terraform apply tfplan

# Or in one command
terraform apply -var="environment=dev"
```

### 5. Deploy Lambda Functions

After infrastructure is deployed:

```bash
# Deploy all Lambda functions
./scripts/deploy-lambdas.sh dev us-east-1

# Or deploy individually
cd src/lambda/s3-processor
zip -r s3-processor.zip index.py
aws lambda update-function-code \
  --function-name serverless-pipeline-s3-processor-dev \
  --zip-file fileb://s3-processor.zip
```

### 6. Verify Deployment

```bash
# Check Terraform outputs
terraform output

# Test API endpoint
API_URL=$(terraform output -raw api_gateway_url)
curl "${API_URL}/health"

# Test event creation
curl -X POST "${API_URL}/events" \
  -H "Content-Type: application/json" \
  -d '{"eventType": "TEST", "payload": {"message": "Hello"}}'

# Upload test image
curl -X POST "${API_URL}/images/upload" \
  -H "Content-Type: application/json" \
  -d '{"filename": "test.jpg", "contentType": "image/jpeg"}'

# Trigger pipeline
curl -X POST "${API_URL}/pipeline" \
  -H "Content-Type: application/json" \
  -d '{"imageId": "test-123", "action": "process"}'
```

### 7. Build Dashboard (Optional)

```bash
# Build production dashboard
cd ..
npm run build

# Deploy to S3 static hosting (optional)
aws s3 sync dist/ s3://your-dashboard-bucket/
```

## Environment Management

### Development

```bash
cd terraform
terraform workspace new dev
terraform apply -var="environment=dev" -var="enable_xray=true"
```

### Staging

```bash
terraform workspace new staging
terraform apply -var="environment=staging" -var="enable_deletion_protection=true"
```

### Production

```bash
terraform workspace new prod
terraform apply -var="environment=prod" \
  -var="enable_deletion_protection=true" \
  -var="enable_xray=true" \
  -var="log_retention_days=30"
```

## Rollback Procedures

### Lambda Rollback

```bash
# List previous versions
aws lambda list-versions-by-function --function-name serverless-pipeline-s3-processor-dev

# Rollback to previous version
aws lambda update-alias \
  --function-name serverless-pipeline-s3-processor-dev \
  --name prod \
  --function-version 2
```

### Infrastructure Rollback

```bash
# Use Terraform state history
cd terraform
terraform state list

# Or restore from backup
terraform apply -var="environment=dev" # re-apply known good config
```

## Troubleshooting

### Common Issues

#### Lambda Permission Denied
```bash
# Check IAM role
aws iam get-role --role-name serverless-pipeline-lambda-exec-dev

# Verify trust policy
aws iam get-role-policy --role-name serverless-pipeline-lambda-exec-dev --policy-name serverless-pipeline-lambda-custom-dev
```

#### DynamoDB Stream Not Triggering
```bash
# Check stream status
aws dynamodb describe-table --table-name serverless-pipeline-events-dev

# Verify event source mapping
aws lambda list-event-source-mappings --function-name serverless-pipeline-dynamodb-processor-dev
```

#### EventBridge Events Not Routing
```bash
# Test event put
aws events put-events --entries '[{"Source":"serverless.pipeline","DetailType":"Test","Detail":"{}","EventBusName":"serverless-pipeline-bus-dev"}]'

# Check rule targets
aws events list-targets-by-rule --rule serverless-pipeline-image-processed-dev --event-bus-name serverless-pipeline-bus-dev
```

#### Step Functions Execution Failed
```bash
# List failed executions
aws stepfunctions list-executions --state-machine-arn $(terraform output -raw state_machine_arn) --status-filter FAILED

# Get execution history
aws stepfunctions get-execution-history --execution-arn <execution-arn>
```

## Monitoring Setup

After deployment, verify monitoring:

1. **CloudWatch Dashboard**: Check `terraform output` for dashboard name
2. **X-Ray Service Map**: Open X-Ray console to see service graph
3. **CloudWatch Alarms**: Verify SNS topic receives alarm notifications
4. **Logs**: Check `/aws/lambda/serverless-pipeline-*` log groups

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy -var="environment=dev"

# Or specific workspace
terraform workspace select dev
terraform destroy -var="environment=dev"
```

**WARNING**: This will delete all data in DynamoDB and S3 buckets.
