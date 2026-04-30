import json
import boto3
from datetime import datetime
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

@xray_recorder.capture('validate')
def handler(event, context):
    """
    Validate step - validates input data before processing
    """
    print(f"Validate step received: {json.dumps(event)}")
    
    image_id = event.get('imageId', '')
    status = event.get('status', '')
    
    validation_result = {
        'imageId': image_id,
        'isValid': True,
        'validationErrors': [],
        'timestamp': datetime.utcnow().isoformat()
    }
    
    if not image_id:
        validation_result['isValid'] = False
        validation_result['validationErrors'].append('imageId is required')
    
    if status not in ['UPLOADED', 'CREATED', 'PROCESSED']:
        validation_result['validationErrors'].append(f'Unexpected status: {status}')
    
    return validation_result
