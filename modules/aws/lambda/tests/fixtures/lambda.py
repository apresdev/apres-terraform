def lambda_handler(event, context):
    print("Hello World")
    return {
        'status': 200,
        'body'  : 'success'
    }