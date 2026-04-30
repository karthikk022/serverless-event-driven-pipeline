import json
import boto3
import os
from datetime import datetime
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', '')

table = dynamodb.Table(TABLE_NAME) if TABLE_NAME else None

@xray_recorder.capture('transform')
def handler(event, context):
    """
    Transform step - transforms data into desired format
    """
    print(f"Transform step received: {json.dumps(event)}")
    
    image_id = event.get('imageId', '')
    
    transformed = {
        'imageId': image_id,
        'transformedAt': datetime.utcnow().isoformat(),
        'format': 'standardized',
        'metadata': {
            'version': '2.0',
            'schema': 'image-processing-v2'
        },
        'tags': ['processed', 'automated'],
        'status': 'TRANSFORMED'
    }
    
    # Update DynamoDB if available
    if table and image_id:
        try:
            table.update_item(
                Key={'PK': f'IMAGE#{image_id}', 'SK': event.get('timestamp', '')},
                UpdateExpression='SET #status = :status, transformedAt = :time',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'TRANSFORMED',
                    ':time': transformed['transformedAt']
                }
            )
        except Exception as e:
            print(f"Error updating DynamoDB: {e}")
    
    return transformed
