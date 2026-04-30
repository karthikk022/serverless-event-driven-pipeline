import json
import boto3
import os
from datetime import datetime
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', '')

table = dynamodb.Table(TABLE_NAME) if TABLE_NAME else None

@xray_recorder.capture('error_handler')
def handler(event, context):
    """
    Error handler step - handles failures in the pipeline
    """
    print(f"Error handler received: {json.dumps(event)}")
    
    # Step Functions sends error info in a specific format
    error = event.get('Error', 'Unknown')
    cause = event.get('Cause', 'No cause provided')
    
    # Extract original input if available
    original_input = event.get('input', {})
    image_id = original_input.get('imageId', 'unknown')
    
    error_record = {
        'imageId': image_id,
        'errorAt': datetime.utcnow().isoformat(),
        'error': error,
        'cause': cause,
        'status': 'ERROR',
        'retryable': error in ['States.Timeout', 'Lambda.ServiceException']
    }
    
    # Store error in DynamoDB
    if table:
        try:
            table.put_item(
                Item={
                    'PK': f'ERROR#{image_id}',
                    'SK': f'TIME#{error_record["errorAt"]}',
                    'imageId': image_id,
                    'error': error,
                    'cause': cause,
                    'timestamp': error_record['errorAt'],
                    'ttl': int((datetime.utcnow().timestamp() + 30 * 24 * 3600))
                }
            )
        except Exception as e:
            print(f"Error storing error record: {e}")
    
    # Return error info for potential retry logic
    return error_record
