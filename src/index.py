def lambda_handler(event, context):
   message = 'Hello {} !'.format(event['queryStringParameters']['msg'])
   return {
       'message' : message
   }
