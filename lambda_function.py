import json

def lambda_handler(event, context):
    try:
        # Handle root path (HTML form)
        if event.get('httpMethod') == 'GET' and event.get('path') == '/':
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'text/html'},
                'body': """
                <html>
                <head>
                    <title>Greeter</title>
                    <style>
                        body { font-family: Arial; max-width: 500px; margin: 0 auto; padding: 20px; }
                        input, button { padding: 8px; margin-top: 10px; }
                    </style>
                </head>
                <body>
                    <h1>Welcome!</h1>
                    <form action="/hello" method="GET">
                        <label for="name">Enter your name:</label><br>
                        <input type="text" id="name" name="name" required><br>
                        <button type="submit">Greet me!</button>
                    </form>
                </body>
                </html>
                """
            }
        
        # Handle API response
        elif event.get('httpMethod') == 'GET' and event.get('path') == '/hello':
            name = event.get('queryStringParameters', {}).get('name', 'World')
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'message': f'Hello, {name}!'})
            }
        
        # Catch-all for invalid paths
        else:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Not found'})
            }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }