import json
import boto3
#Library used to interact with AWS services



# interacting with the dynamodb resource
dynamodb =boto3.resource('dynamodb')

# we call the dynamodb table called cloudresume-test
table = dynamodb.Table('cloudresume-test')


# the lambda function will get an item from the table with an id 0
# the item with id 0 has a property called views

def lambda_handler(event, context):
    response = table.get_item(Key={
        'id':'1'
    })
    # printing the number of views on the production website
    views = response['Item']['views']
    # we increase the number of views by one
    # we record the viewer count
    views = views + 1
    print(views)
    # we updated the table with the new value of views
    respose = table.put_item(Item={
        'id':'1',
        'views':views
    })
    


    return views