import boto3
import json
import math
import os
import re
from botocore.exceptions import ClientError

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
users_table = dynamodb.Table("NetpipeUsers")
BUCKET = "netpipe-bucket"
PART_SIZE = 100 * 1024 * 1024  # 100MB
UPLOAD_URL_TTL = 600
DOWNLOAD_URL_TTL = 600

# Reject anything that isn't a boring filename. No slashes (path traversal),
# no leading dot (hidden/relative), no spaces, no control chars. 1..128 chars.
_NAME_RE = re.compile(r"^(?!\.)[A-Za-z0-9._-]{1,128}$")


def _valid_name(s):
    return isinstance(s, str) and bool(_NAME_RE.fullmatch(s))

def lambda_handler(event, context):
    user_id = "unknown"
    try:
        route = event["routeKey"]
        headers = event.get("headers", {})
        folder_name = headers.get("folder-name")
        file_name = headers.get("file-name")
        declared_size = headers.get("file-size")
        user_id = event["requestContext"]["authorizer"]["lambda"]["user_id"]

        if not _valid_name(folder_name):
            print(f"{user_id}: 400 invalid folder-name {folder_name!r}")
            return _resp(400, {"message": "Invalid folder-name"})

        if route == "GET /list":
            return listFiles(folder_name, user_id)

        if not _valid_name(file_name):
            print(f"{user_id}: 400 invalid file-name {file_name!r}")
            return _resp(400, {"message": "Invalid file-name"})

        key = f"{folder_name}/{file_name}"

        if route == "PUT /send":
            return initiateUpload(key, user_id, declared_size)

        if route == "POST /complete":
            body = json.loads(event.get("body") or "{}")
            upload_id = body.get("upload_id")
            parts = body.get("parts")  # [{"PartNumber": 1, "ETag": "..."}, ...]
            return completeUpload(key, user_id, upload_id, parts)

        if route == "GET /file":
            return getFile(key, user_id)

        print(f"{user_id}: 404 unmatched route {route}")
        return _resp(404, {"message": "How?"})
    except Exception as e:
        print(f"{user_id}: 500 internal server error - {e}")
        return _resp(500, {"message": "Internal server error"})


def initiateUpload(key, user_id, declared_size):
    try:
        declared_size = int(declared_size)
    except (TypeError, ValueError):
        print(f"{user_id}: 400 invalid declared file size for {key}: {declared_size!r}")
        return _resp(400, {"message": "Wrong declared file size"})
    if declared_size <= 0:
        print(f"{user_id}: 400 declared file size must be positive for {key}")
        return _resp(400, {"message": "Wrong declared file size"})

    num_parts = math.ceil(declared_size / PART_SIZE)

    mpu = s3.create_multipart_upload(
        Bucket=BUCKET,
        Key=key,
        Metadata={"user-id": user_id},
    )
    upload_id = mpu["UploadId"]

    presigned_urls = []
    for i in range(num_parts):
        start = i * PART_SIZE
        part_size = min(PART_SIZE, declared_size - start)
        # ContentLength is signed into the URL — S3 rejects PUTs whose body
        # size doesn't match, so the client can't smuggle extra bytes past
        # the declared-size quota check.
        url = s3.generate_presigned_url(
            ClientMethod="upload_part",
            Params={
                "Bucket": BUCKET,
                "Key": key,
                "UploadId": upload_id,
                "PartNumber": i + 1,
                "ContentLength": part_size,
            },
            ExpiresIn=UPLOAD_URL_TTL,
        )
        presigned_urls.append({"part_number": i + 1, "url": url, "size": part_size})

    try:
        users_table.update_item(
            Key={"UserId": user_id},
            UpdateExpression="ADD RemainingMonthUpload :neg, TotalMonthUpload :pos, TotalUpload :pos",
            ConditionExpression="RemainingMonthUpload >= :pos",
            ExpressionAttributeValues={":neg": -declared_size, ":pos": declared_size},
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            print(f"{user_id}: monthly upload quota exceeded")
            return _resp(413, {"message": "monthly upload quota exceeded"})
        raise

    print(f"{user_id}: 200 multipart upload initiated for {key} ({num_parts} parts, {declared_size} bytes)")
    return _resp(200, {
        "upload_id": upload_id,
        "parts": presigned_urls,
    })


def completeUpload(key, user_id, upload_id, parts):
    if not upload_id or not parts:
        print(f"{user_id}: missing upload_id or parts")
        return _resp(400, {"message": "Missing upload_id or parts"})

    try:
        s3.complete_multipart_upload(
            Bucket=BUCKET,
            Key=key,
            UploadId=upload_id,
            MultipartUpload={"Parts": [
                {"PartNumber": p["part_number"], "ETag": p["etag"]}
                for p in parts
            ]},
        )
    except ClientError as e:
        print(f"{user_id}: complete_multipart_upload failed for {key}: {e}")
        return _resp(400, {"message": "Failed to complete upload"})
    

    print(f"{user_id}: 200 multipart upload completed for {key}")
    return _resp(200, {"message": "Upload complete"})


def getFile(key, user_id):
    try:
        head = s3.head_object(Bucket=BUCKET, Key=key)
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("404", "NoSuchKey", "NotFound"):
            print(f"{user_id}: 404 file not found - {key}")
            return _resp(404, {"message": "file not found"})
        raise

    file_size = head["ContentLength"]

    num_parts = math.ceil(file_size / PART_SIZE)
    parts = []
    for i in range(num_parts):
        start = i * PART_SIZE
        end = min(start + PART_SIZE - 1, file_size - 1)
        url = s3.generate_presigned_url(
            ClientMethod="get_object",
            Params={
                "Bucket": BUCKET,
                "Key": key,
                "ResponseContentDisposition": f"attachment; filename={os.path.basename(key)}",
                "Range": f"bytes={start}-{end}",
            },
            ExpiresIn=DOWNLOAD_URL_TTL,
        )
        parts.append({"part_number": i + 1, "url": url, "start": start, "end": end})

    try:
        users_table.update_item(
            Key={"UserId": user_id},
            UpdateExpression="ADD RemainingMonthDownload :neg, TotalMonthDownload :pos, TotalDownload :pos",
            ConditionExpression="RemainingMonthDownload >= :pos",
            ExpressionAttributeValues={":neg": -file_size, ":pos": file_size},
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            print(f"{user_id}: 413 monthly download quota exceeded for {key} ({file_size} bytes)")
            return _resp(413, {"message": "monthly download quota exceeded"})
        raise

    print(f"{user_id}: 200 multipart download initiated for {key} ({num_parts} parts, {file_size} bytes)")
    return _resp(200, {"file_size": file_size, "parts": parts})

def listFiles(folder_name, user_id):
    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=f"{folder_name}/")
    files = [
        {"key": obj["Key"], "size": obj["Size"], "modified": obj["LastModified"].isoformat()}
        for obj in resp.get("Contents", [])
    ]
    print(f"{user_id}: 200 listed {len(files)} file(s) in {folder_name}/")
    return _resp(200, {"files": files})


def _resp(status, body):
    return {"statusCode": status, "body": json.dumps(body)}