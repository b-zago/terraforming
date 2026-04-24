import boto3
import hashlib
import os
import secrets

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("NetpipeUsers")

owner = os.environ["OWNER"]
max_download_mb = int(os.environ["MAX_MB_DOWNLOAD"])
max_download = max_download_mb * 1024 * 1024
max_upload_mb = int(os.environ["MAX_MB_UPLOAD"])
max_upload = max_upload_mb * 1024 * 1024

def register_key(owner: str, max_download: int, max_upload) -> str:
    while True:
        raw_key = generate_api_key()
        user_id = raw_key[:10]
        salt = os.urandom(16).hex()
        key_hash = hashlib.sha256(f"{raw_key}{salt}".encode()).hexdigest()

        try:
            table.put_item(
                Item={
                    "UserId": user_id,
                    "Owner": owner,
                    "AccessKey": {
                        "Hash": key_hash,
                        "Salt": salt,
                    },
                    "TotalMonthDownload": 0,
                    "MaxMonthDownload": max_download,
                    "RemainingMonthDownload": max_download,
                    "TotalDownload": 0,
                    "TotalMonthUpload": 0,
                    "MaxMonthUpload": max_upload,
                    "RemainingMonthUpload": max_upload,
                    "TotalUpload": 0,
                    "DayBucket": 0,
                    "RequestsThisDay": 0,
                },
                ConditionExpression="attribute_not_exists(UserId)"
            )
            return raw_key

        except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
            continue

def generate_api_key() -> str:
    return f"np_{secrets.token_hex(32)}"


def main() -> str:
    key = register_key(owner, max_download, max_upload)
    return key

if __name__ == "__main__":
    print(main())