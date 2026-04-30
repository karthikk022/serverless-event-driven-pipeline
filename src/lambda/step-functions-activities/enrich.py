import json
import boto3
import os
from datetime import datetime
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', '')

table = dynamodb.Table(TABLE_NAME) if TABLE_NAME else None

@xray_recorder.capture('enrich')
def handler(event, context):
    """
    Enrich step - adds additional metadata and context
    """
    print(f"Enrich step received: {json.dumps(event)}")
    
    image_id = event.get('imageId', '')
    
    enriched = {
        'imageId': image_id,
        'enrichedAt': datetime.utcnow().isoformat(),
        'enrichment': {
            'source': 'automated-pipeline',
            'confidence': 0.95,
            'tags': ['enriched', 'automated'],
            'categories': ['image', 'processed']
        },
        'status': 'ENRICHED'
    }
    
    # Update DynamoDB if available
    if table and image_id:
        try:
            table.update_item(
                Key={'PK': f'IMAGE#{image_id}', 'SK': event.get('timestamp', '')},
                UpdateExpression='SET #status = :status, enrichedAt = :time',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'ENRICHED',
                    ':time': enriched['enrichedAt']
                }
            )
        except Exception as e:
            print(f"Error updating DynamoDB: {e}")
    
    return enriched
