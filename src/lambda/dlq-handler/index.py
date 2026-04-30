import json
import boto3
import os
from datetime import datetime
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

TABLE_NAME = os.environ.get('DYNAMODB_TABLE', '')

table = dynamodb.Table(TABLE_NAME) if TABLE_NAME else None

@xray_recorder.capture('handler')
def handler(event, context):
    """
    DLQ Handler - processes failed events from dead letter queue
    """
    print(f"DLQ handler received: {json.dumps(event)}")
    
    processed = []
    
    for record in event.get('Records', []):
        body = record.get('body', '{}')
        if isinstance(body, str):
            try:
                body = json.loads(body)
            except:
                pass
        
        # Log the failed event for analysis
        failure_record = {
            'messageId': record.get('messageId', ''),
            'receiptHandle': record.get('receiptHandle', ''),
            'body': body,
            'attributes': record.get('attributes', {}),
            'receivedAt': datetime.utcnow().isoformat(),
            'status': 'DLQ_RECEIVED'
        }
        
        # Store in DynamoDB for analysis
        if table:
            try:
                table.put_item(
                    Item={
                        'PK': f'DLQ#{record.get("messageId", "unknown")}',
                        'SK': f'TIME#{failure_record["receivedAt"]}',
                        'messageId': record.get('messageId', ''),
                        'body': json.dumps(body),
                        'receivedAt': failure_record['receivedAt'],
                        'ttl': int((datetime.utcnow().timestamp() + 30 * 24 * 3600))
                    }
                )
            except Exception as e:
                print(f"Error storing DLQ record: {e}")
        
        processed.append(failure_record)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed': len(processed),
            'records': processed
        })
    }
