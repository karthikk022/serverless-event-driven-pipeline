import json
import boto3
import os
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')

TABLE_NAME = os.environ['DYNAMODB_TABLE']
EVENT_BUS_NAME = os.environ['EVENT_BUS_NAME']

table = dynamodb.Table(TABLE_NAME)

@xray_recorder.capture('handler')
def handler(event, context):
    """
    Process DynamoDB stream events:
    1. Capture INSERT/MODIFY events
    2. Enrich event data
    3. Trigger downstream processing via EventBridge
    """
    print(f"Received DynamoDB stream event: {json.dumps(event)}")
    
    processed_records = []
    
    for record in event.get('Records', []):
        event_name = record.get('eventName')
        
        if event_name not in ['INSERT', 'MODIFY']:
            print(f"Skipping {event_name} event")
            continue
        
        new_image = record.get('dynamodb', {}).get('NewImage', {})
        old_image = record.get('dynamodb', {}).get('OldImage', {})
        
        # Extract key attributes
        pk = new_image.get('PK', {}).get('S', '')
        sk = new_image.get('SK', {}).get('S', '')
        status = new_image.get('status', {}).get('S', '')
        
        # Only process image records that are newly uploaded or modified
        if not pk.startswith('IMAGE#'):
            continue
        
        image_id = pk.replace('IMAGE#', '')
        
        # Check if status changed to trigger downstream
        old_status = old_image.get('status', {}).get('S', '')
        
        if status == 'UPLOADED' and old_status != 'UPLOADED':
            # New upload - trigger processing
            event_detail = {
                'imageId': image_id,
                'status': status,
                'timestamp': new_image.get('createdAt', {}).get('S', ''),
                'triggerSource': 'DynamoDBStream',
                'changeType': 'NEW_UPLOAD'
            }
            
            try:
                events.put_events(
                    Entries=[
                        {
                            'Source': 'serverless.pipeline',
                            'DetailType': 'EventCreated',
                            'Detail': json.dumps(event_detail),
                            'EventBusName': EVENT_BUS_NAME
                        }
                    ]
                )
                print(f"Emitted downstream event for {image_id}")
            except Exception as e:
                print(f"Error emitting EventBridge event: {e}")
        
        elif status == 'PROCESSED':
            # Processing complete - trigger notification
            event_detail = {
                'imageId': image_id,
                'status': status,
                'timestamp': new_image.get('updatedAt', {}).get('S', ''),
                'triggerSource': 'DynamoDBStream',
                'changeType': 'PROCESSING_COMPLETE'
            }
            
            try:
                events.put_events(
                    Entries=[
                        {
                            'Source': 'serverless.pipeline',
                            'DetailType': 'PipelineTriggered',
                            'Detail': json.dumps(event_detail),
                            'EventBusName': EVENT_BUS_NAME
                        }
                    ]
                )
                print(f"Emitted pipeline trigger for {image_id}")
            except Exception as e:
                print(f"Error emitting EventBridge event: {e}")
        
        processed_records.append({
            'imageId': image_id,
            'status': status,
            'eventName': event_name
        })
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'DynamoDB stream events processed',
            'processed': len(processed_records),
            'records': processed_records
        })
    }
