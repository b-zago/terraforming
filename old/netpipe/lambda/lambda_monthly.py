import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
users_table = dynamodb.Table("NetpipeUsers")

def lambda_handler(event, context):
    try:
        response = users_table.scan(ProjectionExpression="UserId")
        users = response.get("Items", [])

        while "LastEvaluatedKey" in response:
            response = users_table.scan(
                ProjectionExpression="UserId",
                ExclusiveStartKey=response["LastEvaluatedKey"],
            )
            users.extend(response.get("Items", []))

        for user in users:
            user_id = user["UserId"]
            users_table.update_item(
                Key={"UserId": user_id},
                UpdateExpression="SET TotalMonthDownload = :zero, TotalMonthUpload = :zero, RemainingMonthDownload = MaxMonthDownload, RemainingMonthUpload = MaxMonthUpload ",
                ExpressionAttributeValues={":zero": 0},
            )
            print(f"{user_id}: monthly stats reset")

        print(f"monthly reset complete: {len(users)} user(s) updated")
        return {"statusCode": 200, "body": f"Reset {len(users)} user(s)"}
    except ClientError as e:
        print(f"monthly reset failed: {e}")
        return {"statusCode": 500, "body": "Internal server error"}
