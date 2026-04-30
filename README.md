# Serverless Event-Driven Pipeline

A production-ready event-driven serverless architecture using AWS Lambda, API Gateway, EventBridge, Step Functions, DynamoDB Streams, and X-Ray tracing. Infrastructure managed entirely with Terraform.

## Architecture Overview

```
                    ┌─────────────────────────────────────────────────────────────┐
                    │                    INGESTION LAYER                          │
                    │  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐    │
                    │  │   S3     │    │ API Gateway  │    │ DynamoDB Streams │    │
                    │  │ (Images) │    │  (REST API)  │    │   (CDC Events)   │    │
                    │  └────┬─────┘    └──────┬───────┘    └────────┬─────────┘    │
                    └───────┼─────────────────┼─────────────────────┼──────────────┘
                            │                 │                      │
                    ┌───────▼─────────────────▼───────────────────────▼──────────────┐
                    │                 COMPUTE / PROCESSING LAYER                      │
                    │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
                    │  │ S3 Processor │  │ API Handler  │  │  Stream Processor   │  │
                    │  │   (Lambda)   │  │   (Lambda)   │  │     (Lambda)        │  │
                    │  └──────┬───────┘  └──────┬───────┘  └──────────┬──────────┘  │
                    │         │                  │                      │            │
                    │         └──────────────────┼──────────────────────┘            │
                    │                            │                                     │
                    │                            ▼                                     │
                    │                   ┌─────────────────┐                            │
                    │                   │   EventBridge   │                            │
                    │                   │  (Event Bus)    │                            │
                    │                   └────────┬────────┘                            │
                    │                            │                                     │
                    │         ┌──────────────────┼──────────────────┐                 │
                    │         ▼                  ▼                  ▼                 │
                    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
                    │  │   Lambda     │  │  Step Func   │  │     SNS      │           │
                    │  │  Processor   │  │ Orchestrator │  │   Alerts     │           │
                    │  └──────────────┘  └──────┬───────┘  └──────────────┘           │
                    │                           │                                      │
                    │              ┌────────────┼────────────┐                         │
                    │              ▼            ▼            ▼                         │
                    │        ┌─────────┐ ┌─────────┐ ┌─────────┐                     │
                    │        │Validate │ │Transform│ │ Enrich  │                     │
                    │        │ Lambda   │ │ Lambda  │ │ Lambda  │                     │
                    │        └────┬─────┘ └────┬────┘ └────┬────┘                     │
                    │             └─────────────┴───────────┘                        │
                    │                           │                                      │
                    │                           ▼                                      │
                    │                    ┌─────────┐                                   │
                    │                    │ Notify  │                                   │
                    │                    │ Lambda   │                                   │
                    │                    └────┬────┘                                   │
                    └─────────────────────────┼────────────────────────────────────────┘
                                              │
                    ┌───────────────────────────▼────────────────────────────────────────┐
                    │                      OBSERVABILITY LAYER                            │
                    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐    │
                    │  │   X-Ray      │  │ CloudWatch   │  │   CloudWatch Logs    │    │
                    │  │ (Tracing)    │  │  (Metrics)   │  │     (Logging)        │    │
                    │  └──────────────┘  └──────────────┘  └──────────────────────┘    │
                    └────────────────────────────────────────────────────────────────────┘
```

## Key Features

- **S3 Event-Driven Processing**: Image uploads to S3 automatically trigger Lambda for processing
- **DynamoDB Streams**: Capture item-level changes and trigger downstream Lambda functions
- **EventBridge Event Bus**: Custom event bus with routing rules to multiple targets (Lambda, Step Functions, SNS)
- **Step Functions Orchestration**: Complex workflows with parallel processing, error handling, and retries
- **X-Ray Distributed Tracing**: End-to-end tracing across all Lambda functions and Step Functions
- **Terraform IaC**: 100% infrastructure as code with modular design
- **API Gateway REST API**: HTTP endpoints for manual event injection and health checks
- **Dead Letter Queues**: SQS-based DLQ for failed Lambda and Step Functions executions
- **CloudWatch Dashboard**: Pre-built dashboard with key metrics and alarms

## Technology Stack

| Component | Technology |
|-----------|------------|
| IaC | Terraform 1.5+ |
| Compute | AWS Lambda (Python 3.11, Node.js 20) |
| API | API Gateway REST |
| Events | Amazon EventBridge |
| Orchestration | AWS Step Functions |
| Database | DynamoDB + DynamoDB Streams |
| Storage | Amazon S3 |
| Tracing | AWS X-Ray |
| Monitoring | CloudWatch Logs, Metrics, Alarms |
| Notifications | Amazon SNS |
| DLQ | Amazon SQS |
| Frontend | React + TypeScript + Tailwind CSS |

## Project Structure

```
serverless-event-driven-pipeline/
├── terraform/                          # Infrastructure as Code
│   ├── main.tf                         # Root module configuration
│   ├── variables.tf                    # Input variables
│   ├── outputs.tf                      # Output values
│   ├── modules/
│   │   ├── iam/                        # IAM roles and policies
│   │   ├── s3/                         # S3 buckets and notifications
│   │   ├── dynamodb/                   # DynamoDB tables with streams
│   │   ├── lambda/                     # Lambda functions and event mappings
│   │   ├── api_gateway/                # REST API configuration
│   │   ├── eventbridge/                # Event bus, rules, and targets
│   │   ├── step_functions/             # State machine definition
│   │   ├── xray/                       # Tracing configuration
│   │   └── cloudwatch/                 # Dashboards and alarms
│   └── environments/
│       └── dev/                        # Environment-specific configs
├── src/
│   ├── lambda/                         # Lambda function source code
│   │   ├── s3-processor/               # S3 image processing (Python)
│   │   ├── dynamodb-stream-processor/ # Stream record processing (Python)
│   │   ├── eventbridge-processor/       # Event routing (Python)
│   │   ├── api-handler/                 # API Gateway handler (Python)
│   │   ├── dlq-handler/                 # Dead letter queue handler (Python)
│   │   └── step-functions-activities/   # Step Functions task handlers
│   │       ├── validate.py
│   │       ├── transform.py
│   │       ├── enrich.py
│   │       ├── notify.py
│   │       └── error_handler.py
│   ├── step-functions/
│   │   └── pipeline-workflow.asl.json  # Step Functions ASL definition
│   ├── pages/
│   │   └── Dashboard.tsx               # Monitoring dashboard
│   └── components/
│       ├── ArchitectureDiagram.tsx     # Interactive architecture view
│       ├── EventTriggerPanel.tsx       # Event simulation panel
│       └── PipelineMonitor.tsx         # Pipeline execution monitor
├── docs/
│   ├── architecture.md                 # Detailed architecture documentation
│   └── deployment-guide.md             # Step-by-step deployment guide
├── scripts/
│   ├── deploy-lambdas.sh              # Lambda deployment script
│   ├── setup-local.sh                 # Local development setup
│   └── run-tests.sh                   # Test execution script
├── README.md
└── .gitignore
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- Python 3.11+
- Node.js 20+
- Docker (for local Lambda testing)

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd serverless-event-driven-pipeline
```

### 2. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

### 3. Deploy Lambda Code

```bash
./scripts/deploy-lambdas.sh
```

### 4. Verify Deployment

```bash
terraform output
```

### 5. Build Dashboard (Optional)

```bash
cd ..
npm install
npm run build
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/events` | GET | List events from DynamoDB |
| `/events` | POST | Create a new event |
| `/images/upload` | POST | Generate S3 pre-signed URL |
| `/pipeline` | POST | Trigger Step Functions execution |

## Event Flow Examples

### S3 Image Upload Flow

1. Image uploaded to `s3://{bucket}/uploads/`
2. S3 event notification triggers `s3-processor` Lambda
3. Lambda extracts metadata and stores in DynamoDB
4. EventBridge `ImageProcessed` event emitted
5. DynamoDB Stream captures the new item
6. `stream-processor` Lambda triggers downstream processing
7. EventBridge routes to Step Functions for workflow orchestration

### Manual Event Flow

1. POST `/events` with custom payload
2. API Handler Lambda stores in DynamoDB
3. EventBridge `EventCreated` event emitted
4. Event rule triggers Step Functions execution
5. Workflow: Validate → Transform (parallel) → Enrich → Notify

## Step Functions Workflow

```
┌─────────────┐
│ ValidateInput│
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│Parallel     │────▶│ TransformData│
│Processing   │     └─────────────┘
│             │     ┌─────────────┐
│             │────▶│  EnrichData  │
└──────┬──────┘     └─────────────┘
       │
       ▼
┌─────────────┐
│ MergeResults│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│NotifyCompletion│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│EmitSuccessEvent│
└─────────────┘
```

## Monitoring and Observability

### X-Ray Tracing
- Active tracing enabled on all Lambda functions
- Step Functions tracing enabled
- Custom subsegments for business logic
- Service map visualization in AWS Console

### CloudWatch Dashboard
- Lambda invocation metrics
- Error rates and duration percentiles
- Step Functions execution metrics
- DynamoDB throughput metrics
- Custom application metrics

### Alarms
- Lambda error count > 5 in 5 minutes
- Lambda p99 duration > 10 seconds
- Step Functions execution failures
- DLQ message count > 0

## Testing

### Unit Tests
```bash
# Python Lambda tests
cd src/lambda
python -m pytest tests/

# Terraform validation
terraform validate
terraform plan
```

### Integration Tests
```bash
# Deploy to dev environment
terraform apply -var="environment=dev"

# Run integration test suite
./scripts/run-tests.sh
```

### Load Testing
```bash
# Using Artillery or k6
artillery run tests/load-test.yml
```

## Cleanup

```bash
cd terraform
terraform destroy -var="environment=dev"
```

## Security Considerations

- All S3 buckets have public access blocked
- DynamoDB tables use server-side encryption
- Lambda functions use least-privilege IAM roles
- API Gateway endpoints can be secured with API keys or authorizers
- VPC not required but can be added for private resource access
- X-Ray tracing data is encrypted in transit and at rest

## Cost Optimization

- Lambda uses appropriate memory sizes (128MB-512MB)
- DynamoDB on-demand billing for unpredictable workloads
- S3 lifecycle policies for DLQ cleanup
- CloudWatch log retention set to 14 days
- EventBridge archive retention limited to 7 days

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see LICENSE file for details

## Contact

For questions or support, please open an issue in the GitHub repository.

---

**Built with** Terraform, AWS Lambda, EventBridge, Step Functions, DynamoDB, S3, X-Ray, React, TypeScript, and Tailwind CSS.
