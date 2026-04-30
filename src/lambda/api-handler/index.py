import json
import boto3
import os
import base64
import uuid
from datetime import datetime
from urllib.parse import parse_qs

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')
sfn = boto3.client('stepfunctions')

TABLE_NAME = os.environ['DYNAMODB_TABLE']
IMAGE_BUCKET = os.environ['IMAGE_BUCKET']
EVENT_BUS_NAME = os.environ['EVENT_BUS_NAME']
STEP_FUNCTION_ARN = os.environ['STEP_FUNCTION_ARN']

table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """
    API Gateway handler - routes requests:
    - GET /events: List events from DynamoDB
    - POST /events: Create a new event
    - POST /images/upload: Generate pre-signed URL for upload
    - POST /pipeline: Trigger a pipeline execution
    - GET /health: Health check
    """
    print(f"Received API event: {json.dumps(event)}")
    
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '')
    
    # Route requests
    if path == '/health':
        return health_check()
    
    elif path == '/events':
        if http_method == 'GET':
            return list_events(event)
        elif http_method == 'POST':
            return create_event(event)
    
    elif path == '/images/upload':
        if http_method == 'POST':
            return generate_upload_url(event)
    
    elif path == '/pipeline':
        if http_method == 'POST':
            return trigger_pipeline(event)
    
    return {
        'statusCode': 404,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'error': 'Not found'})
    }

def health_check():
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'status': 'healthy',
            'service': 'serverless-event-pipeline',
            'timestamp': datetime.utcnow().isoformat()
        })
    }

def list_events(event):
    try:
        # Parse query parameters
        query = event.get('queryStringParameters') or {}
        limit = int(query.get('limit', 20))
        status = query.get('status')
        
        if status:
            # Query by status using GSI
            response = table.query(
                IndexName='GSI1',
                KeyConditionExpression='GSI1PK = :pk',
                FilterExpression='#status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':pk': 'BUCKET#*',
                    ':status': status
                },
                Limit=limit,
                ScanIndexForward=False
            )
        else:
            # Scan for recent items
            response = table.scan(
                Limit=limit
            )
        
        items = response.get('Items', [])
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'count': len(items),
                'events': items
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def create_event(event):
    try:
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)
        
        event_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        item = {
            'PK': f'EVENT#{event_id}',
            'SK': f'TIME#{timestamp}',
            'GSI1PK': f'TYPE#{body.get("eventType", "GENERIC")}',
            'GSI1SK': f'TIME#{timestamp}',
            'eventId': event_id,
            'eventType': body.get('eventType', 'GENERIC'),
            'payload': body.get('payload', {}),
            'status': 'CREATED',
            'createdAt': timestamp,
            'ttl': int((datetime.utcnow().timestamp() + 30 * 24 * 3600))
        }
        
        table.put_item(Item=item)
        
        # Emit EventBridge event
        events.put_events(
            Entries=[
                {
                    'Source': 'serverless.pipeline',
                    'DetailType': 'EventCreated',
                    'Detail': json.dumps({
                        'eventId': event_id,
                        'eventType': item['eventType'],
                        'timestamp': timestamp
                    }),
                    'EventBusName': EVENT_BUS_NAME
                }
            ]
        )
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'eventId': event_id,
                'status': 'created',
                'timestamp': timestamp
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def generate_upload_url(event):
    try:
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)
        
        filename = body.get('filename', 'image.jpg')
        content_type = body.get('contentType', 'image/jpeg')
        
        # Generate unique key
        key = f"uploads/{uuid.uuid4()}-{filename}"
        
        # Generate pre-signed URL for direct upload
        presigned_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': IMAGE_BUCKET,
                'Key': key,
                'ContentType': content_type
            },
            ExpiresIn=300  # 5 minutes
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'uploadUrl': presigned_url,
                'key': key,
                'bucket': IMAGE_BUCKET,
                'expiresIn': 300
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def trigger_pipeline(event):
    try:
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)
        
        # Start Step Functions execution
        execution_input = {
            'triggerSource': 'API',
            'timestamp': datetime.utcnow().isoformat(),
            'payload': body
        }
        
        response = sfn.start_execution(
            stateMachineArn=STEP_FUNCTION_ARN,
            input=json.dumps(execution_input)
        )
        
        return {
            'statusCode': 202,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'executionArn': response['executionArn'],
                'startDate': response['startDate'].isoformat(),
                'status': 'started'
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
