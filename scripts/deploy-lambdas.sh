#!/bin/bash
set -e

echo "🚀 Deploying Lambda functions..."

LAMBDA_DIR="src/lambda"
PROJECT_NAME="serverless-pipeline"
ENVIRONMENT="${1:-dev}"
REGION="${2:-us-east-1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

deploy_lambda() {
    local name=$1
    local dir=$2
    local handler=$3
    local runtime=$4
    
    echo -e "${YELLOW}Deploying ${name}...${NC}"
    
    # Create deployment package
    cd "${dir}"
    
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt -t . --quiet
    fi
    
    zip -r "${name}.zip" . -x "*.zip" -x "*.pyc" -x "__pycache__/*" -q
    
    # Update Lambda function code
    aws lambda update-function-code \
        --function-name "${PROJECT_NAME}-${name}-${ENVIRONMENT}" \
        --zip-file "fileb://${name}.zip" \
        --region "${REGION}" \
        --no-cli-pager
    
    cd - > /dev/null
    
    echo -e "${GREEN}✓ ${name} deployed${NC}"
}

# Deploy all Lambda functions
deploy_lambda "s3-processor" "${LAMBDA_DIR}/s3-processor" "index.handler" "python3.11"
deploy_lambda "dynamodb-processor" "${LAMBDA_DIR}/dynamodb-stream-processor" "index.handler" "python3.11"
deploy_lambda "eventbridge-processor" "${LAMBDA_DIR}/eventbridge-processor" "index.handler" "python3.11"
deploy_lambda "api-handler" "${LAMBDA_DIR}/api-handler" "index.handler" "python3.11"
deploy_lambda "dlq-handler" "${LAMBDA_DIR}/dlq-handler" "index.handler" "python3.11"
deploy_lambda "step-validate" "${LAMBDA_DIR}/step-functions-activities" "validate.handler" "python3.11"
deploy_lambda "step-transform" "${LAMBDA_DIR}/step-functions-activities" "transform.handler" "python3.11"
deploy_lambda "step-enrich" "${LAMBDA_DIR}/step-functions-activities" "enrich.handler" "python3.11"
deploy_lambda "step-notify" "${LAMBDA_DIR}/step-functions-activities" "notify.handler" "python3.11"
deploy_lambda "step-error-handler" "${LAMBDA_DIR}/step-functions-activities" "error_handler.handler" "python3.11"

echo -e "${GREEN}🎉 All Lambda functions deployed successfully!${NC}"
