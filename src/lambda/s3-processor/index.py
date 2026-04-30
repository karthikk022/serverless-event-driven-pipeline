import json
import boto3
import os
import uuid
from datetime import datetime
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')

TABLE_NAME = os.environ['DYNAMODB_TABLE']
EVENT_BUS_NAME = os.environ['EVENT_BUS_NAME']
PROCESSED_BUCKET = os.environ['PROCESSED_BUCKET']

table = dynamodb.Table(TABLE_NAME)

@xray_recorder.capture('handler')
def handler(event, context):
    """
    Process S3 image upload events:
    1. Extract image metadata
    2. Store metadata in DynamoDB
    3. Emit EventBridge event for downstream processing
    4. Optional: Create thumbnail, extract EXIF data
    """
    print(f"Received S3 event: {json.dumps(event)}")
    
    results = []
    
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        event_name = record['eventName']
        event_time = record['eventTime']
        
        image_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        # Get object metadata
        try:
            head_response = s3.head_object(Bucket=bucket, Key=key)
            content_type = head_response.get('ContentType', 'unknown')
            content_length = head_response.get('ContentLength', 0)
            etag = head_response.get('ETag', '').strip('"')
        except Exception as e:
            print(f"Error getting object metadata: {e}")
            content_type = 'unknown'
            content_length = 0
            etag = ''
        
        # Store event in DynamoDB
        item = {
            'PK': f'IMAGE#{image_id}',
            'SK': f'META#{timestamp}',
            'GSI1PK': f'BUCKET#{bucket}',
            'GSI1SK': f'TIME#{timestamp}',
            'imageId': image_id,
            'bucket': bucket,
            'key': key,
            'eventName': event_name,
            'eventTime': event_time,
            'contentType': content_type,
            'size': content_length,
            'etag': etag,
            'status': 'UPLOADED',
            'createdAt': timestamp,
            'ttl': int((datetime.utcnow().timestamp() + 30 * 24 * 3600))  # 30 days TTL
        }
        
        try:
            table.put_item(Item=item)
            print(f"Stored metadata for {key}")
        except Exception as e:
            print(f"Error storing metadata: {e}")
            raise
        
        # Emit EventBridge event
        event_detail = {
            'imageId': image_id,
            'bucket': bucket,
            'key': key,
            'contentType': content_type,
            'size': content_length,
            'timestamp': timestamp,
            'status': 'UPLOADED'
        }
        
        try:
            events.put_events(
                Entries=[
                    {
                        'Source': 'serverless.pipeline',
                        'DetailType': 'ImageProcessed',
                        'Detail': json.dumps(event_detail),
                        'EventBusName': EVENT_BUS_NAME
                    }
                ]
            )
            print(f"Emitted EventBridge event for {image_id}")
        except Exception as e:
            print(f"Error emitting EventBridge event: {e}")
        
        results.append({
            'imageId': image_id,
            'key': key,
            'status': 'processed'
        })
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'S3 events processed successfully',
            'processed': len(results),
            'results': results
        })
    }
