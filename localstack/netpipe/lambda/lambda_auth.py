import hmac
import hashlib
import boto3
import time
from botocore.exceptions import ClientError


DAILY_LIMIT = 1000

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("NetpipeUsers")

def lambda_handler(event, context):
    headers = event.get("headers", {})
    raw_key = headers.get("authorization")
    ip = event.get("requestContext", {}).get("http", {}).get("sourceIp")

    if not raw_key:
        print(f"{ip}: denied - no token")
        return {"isAuthorized": False}

    user_id = raw_key[:10]

    try:
        response = table.get_item(Key={"UserId": user_id})
    except ClientError as e:
        print(f"{ip}: {user_id}: denied - dynamodb error: {e}")
        return {"isAuthorized": False}

    item = response.get("Item")

    if not item:
        print(f"{ip}: {user_id}: denied: user not found")
        return {"isAuthorized": False}

    stored_hash = item["AccessKey"]["Hash"]
    stored_salt = item["AccessKey"]["Salt"]

    computed_hash = hashlib.sha256(f"{raw_key}{stored_salt}".encode()).hexdigest()

    if hmac.compare_digest(computed_hash, stored_hash):
        if not _within_daily_limit(user_id):
            print(f"{ip}: {user_id}: denied - daily limit exceeded")
            return {"isAuthorized": False}
        print(f"{ip}: {user_id}: allowed owner - {item['Owner']}")
        return {
            "isAuthorized": True,
            "context": {"user_id": user_id},
        }



    print(f"{ip}: {user_id}: denied - invalid key")
    return {"isAuthorized": False}


def _within_daily_limit(user_id):
    """Atomic fixed-window day counter. True if the user is still under cap."""
    today = int(time.time() // 86400)

    try:
        resp = table.update_item(
            Key={"UserId": user_id},
            UpdateExpression="ADD RequestsThisDay :one",
            ConditionExpression="DayBucket = :today",
            ExpressionAttributeValues={":one": 1, ":today": today},
            ReturnValues="ALL_NEW",
        )
        count = resp["Attributes"]["RequestsThisDay"]
    except ClientError as e:
        if e.response["Error"]["Code"] != "ConditionalCheckFailedException":
            raise
        # Rolled to a new day (or first ever) — reset the window.
        table.update_item(
            Key={"UserId": user_id},
            UpdateExpression="SET DayBucket = :today, RequestsThisDay = :one",
            ExpressionAttributeValues={":today": today, ":one": 1},
        )
        count = 1

    return count <= DAILY_LIMIT