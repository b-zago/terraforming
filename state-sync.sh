#!/bin/bash
source .env

mapfile -t sensitive < <(aws s3 ls s3://$PRIVATE_S3_BUCKET/dev --recursive | awk '{print $4}')

if [ ${#sensitive[@]} -eq 0 ]; then
    echo "Fetching files from S3 failed!"
    exit 1
fi

mapfile -t paths < <(printf '%s\n' "${sensitive[@]}" | sed "s|dev/||g")

echo "Getting mandatory files..."
for i in "${!sensitive[@]}"; do
    download_output=$(aws s3 cp s3://$PRIVATE_S3_BUCKET/${sensitive[$i]} ${paths[$i]})
    if [ $? -eq 0 ]; then
        echo "Got ${paths[$i]}!"
    else
        echo "Error for ${paths[$i]}!"
        echo "$download_output"
    fi
done