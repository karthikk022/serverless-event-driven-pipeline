import json
import boto3
import os
from datetime import datetime
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
sfn = boto3.client('stepfunctions')

TABLE_NAME = os.environ['DYNAMODB_TABLE']

table = dynamodb.Table(TABLE_NAME)

@xray_recorder.capture('handler')
def handler(event, context):
    """
    Process EventBridge events:
    1. Route events to appropriate targets
    2. Update DynamoDB status
    3. Trigger Step Functions workflows
    """
    print(f"Received EventBridge event: {json.dumps(event)}")
    
    # EventBridge events have a specific structure
    detail_type = event.get('detail-type', '')
    source = event.get('source', '')
    detail = event.get('detail', {})
    
    if isinstance(detail, str):
        detail = json.loads(detail)
    
    image_id = detail.get('imageId', '')
    status = detail.get('status', '')
    
    result = {
        'detailType': detail_type,
        'source': source,
        'imageId': image_id,
        'actions': []
    }
    
    # Route based on event type
    if detail_type == 'ImageProcessed':
        # Update DynamoDB
        try:
            table.update_item(
                Key={
                    'PK': f'IMAGE#{image_id}',
                    'SK': detail.get('timestamp', '')
                },
                UpdateExpression='SET #status = :status, eventBridgeReceived = :time',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'EVENTBRIDGE_RECEIVED',
                    ':time': json.dumps(datetime.utcnow().isoformat())
                }
            )
            result['actions'].append('updated_dynamodb')
        except Exception as e:
            print(f"Error updating DynamoDB: {e}")
    
    elif detail_type == 'PipelineTriggered':
        # Trigger Step Functions workflow
        try:
            step_input = {
                'imageId': image_id,
                'status': status,
                'timestamp': detail.get('timestamp', ''),
                'source': detail.get('triggerSource', '')
            }
            
            # Get Step Functions ARN from environment or construct it
            sfn_arn = os.environ.get('STEP_FUNCTION_ARN', '')
            if sfn_arn:
                response = sfn.start_execution(
                    stateMachineArn=sfn_arn,
                    input=json.dumps(step_input)
                )
                result['actions'].append('started_step_functions')
                result['executionArn'] = response['executionArn']
        except Exception as e:
            print(f"Error starting Step Functions: {e}")
    
    elif detail_type == 'EventCreated':
        # Log and track event
        result['actions'].append('logged_event')
    
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }
