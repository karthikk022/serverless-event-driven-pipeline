import json
import boto3
import os
from datetime import datetime
from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()

sns = boto3.client('sns')

@xray_recorder.capture('notify')
def handler(event, context):
    """
    Notify step - sends notifications about pipeline completion
    """
    print(f"Notify step received: {json.dumps(event)}")
    
    image_id = event.get('imageId', '')
    
    notification = {
        'imageId': image_id,
        'notifiedAt': datetime.utcnow().isoformat(),
        'channel': 'eventbridge',
        'message': f'Pipeline completed for image {image_id}',
        'status': 'NOTIFIED'
    }
    
    # Publish to SNS if topic ARN is available
    topic_arn = os.environ.get('SNS_TOPIC_ARN', '')
    if topic_arn:
        try:
            sns.publish(
                TopicArn=topic_arn,
                Subject=f'Pipeline Complete: {image_id}',
                Message=json.dumps(notification)
            )
        except Exception as e:
            print(f"Error publishing to SNS: {e}")
    
    return notification
