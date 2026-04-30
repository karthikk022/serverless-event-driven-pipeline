# Architecture Documentation

## System Design

The Serverless Event-Driven Pipeline is designed to demonstrate enterprise-grade event-driven architecture patterns using AWS managed services.

### Design Principles

1. **Loose Coupling**: Services communicate through events, not direct calls
2. **Async Processing**: All heavy processing is asynchronous via events and queues
3. **Observability**: Every component emits traces, logs, and metrics
4. **Resilience**: Built-in retry logic, DLQs, and circuit breaker patterns
5. **Scalability**: Serverless components scale automatically with demand

### Event Flow Patterns

#### Pattern 1: S3 → Lambda → DynamoDB → Stream → EventBridge → Step Functions

This is the primary image processing flow:

1. User uploads image to S3
2. S3 emits `ObjectCreated` event
3. `s3-processor` Lambda extracts metadata
4. Metadata written to DynamoDB
5. DynamoDB Stream captures the insert
6. `stream-processor` Lambda reads the stream record
7. EventBridge receives `ImageProcessed` event
8. Event rule triggers Step Functions workflow
9. Workflow: Validate → Transform + Enrich (parallel) → Merge → Notify

#### Pattern 2: API Gateway → Lambda → DynamoDB → EventBridge

This is the manual event injection flow:

1. Client calls POST `/events`
2. `api-handler` Lambda validates input
3. Event written to DynamoDB
4. EventBridge receives `EventCreated` event
5. Event rule triggers downstream processing

#### Pattern 3: EventBridge Multi-Target Routing

EventBridge routes events to multiple targets:

- **Lambda Processor**: For real-time processing
- **Step Functions**: For complex workflows
- **SNS**: For notifications and fan-out
- **Archive**: For replay and audit

### Data Model

#### DynamoDB Single-Table Design

```
PK: IMAGE#{uuid}        SK: META#{timestamp}
  - image metadata, status tracking

PK: EVENT#{uuid}        SK: TIME#{timestamp}
  - generic events

PK: ERROR#{uuid}        SK: TIME#{timestamp}
  - error records for analysis

PK: DLQ#{messageId}     SK: TIME#{timestamp}
  - dead letter queue records

GSI1: GSI1PK / GSI1SK
  - Query by bucket or event type
```

### State Machine Design

The Step Functions workflow implements the Saga pattern with compensating transactions:

1. **Validate**: Input validation with schema checking
2. **Parallel Processing**: Transform and Enrich run concurrently
   - **Transform**: Standardize data format
   - **Enrich**: Add metadata and context
3. **Merge**: Combine parallel results
4. **Notify**: Send completion notification
5. **Emit**: Publish final event to EventBridge

Error handling:
- Each step has retry policies (exponential backoff)
- Failed executions are captured in error handler
- Error records stored in DynamoDB for analysis
- DLQ receives unprocessable messages

### Security Architecture

| Layer | Control |
|-------|---------|
| Network | API Gateway throttling, WAF optional |
| Authentication | IAM roles with least privilege |
| Encryption | S3 SSE-S3, DynamoDB SSE, TLS in transit |
| Audit | CloudTrail, X-Ray tracing |
| Data Protection | TTL for automatic data expiration |

### Performance Characteristics

| Component | Latency | Throughput |
|-----------|---------|------------|
| API Gateway | < 10ms | 10,000 RPS |
| Lambda | 100-500ms | Auto-scaling |
| DynamoDB | < 10ms | On-demand |
| EventBridge | < 500ms | 10,000 events/sec |
| Step Functions | 1-5s | Express workflows |

### Cost Structure (Monthly Estimate)

| Component | Cost |
|-----------|------|
| Lambda (1M invocations) | ~$20 |
| DynamoDB (1M writes, 10M reads) | ~$15 |
| EventBridge (1M events) | ~$10 |
| Step Functions (100K transitions) | ~$25 |
| API Gateway (1M requests) | ~$35 |
| X-Ray | ~$5 |
| CloudWatch | ~$10 |
| S3 | ~$5 |
| **Total** | **~$125/month** |

## Scaling Considerations

### Vertical Scaling
- Lambda memory: 128MB - 10GB
- DynamoDB: On-demand or provisioned with auto-scaling

### Horizontal Scaling
- Lambda concurrency: 1000 default (increasable)
- DynamoDB partitions: Automatic
- EventBridge: 10,000 events/sec per region

### Backpressure
- SQS DLQ for failed messages
- API Gateway throttling (10,000 RPS default)
- Lambda reserved concurrency limits

## Disaster Recovery

| Strategy | Implementation |
|----------|---------------|
| Backup | S3 versioning, DynamoDB PITR |
| Cross-Region | EventBridge event buses in multiple regions |
| RTO | < 15 minutes (re-deploy Terraform) |
| RPO | < 5 minutes (continuous streaming) |
