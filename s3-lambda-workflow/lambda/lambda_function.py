import json

def lambda_handler(event, context):

    for record in event['Records']:

        body = json.loads(record['body'])

        for s3_record in body['Records']:
            filename = s3_record['s3']['object']['key']
            print(f"File uploaded: {filename}")

    return {
        'statusCode': 200
    }