# netpipe

A minimal file transfer service on AWS. Clients upload and download files through presigned S3 URLs, authenticated by an API key, with per-user monthly upload/download quotas.

## How it works

Requests hit API Gateway, an authorizer Lambda validates the API key against DynamoDB, and the core Lambda issues a presigned S3 URL (single or multipart) for the client to transfer the file directly to/from S3. The declared file size is baked into the presigned URL's conditions, so S3 rejects uploads that don't match — preventing clients from under-declaring their size to bypass the quota check. Every transfer debits the user's monthly quota in DynamoDB. Uploaded objects expire from S3 after 1 day.

## AWS diagram

![Aws diagram](docs/diagram.svg)

## Components

- **`lambda_auth`** — validates the API key against DynamoDB and enforces a daily request limit.
- **`lambda_core`** — issues presigned S3 URLs for upload/download/list and updates the user's monthly quota.
- **`lambda_monthly`** — scheduled on the 1st of each month to reset every user's monthly counters.
- **`register_user/`** — Docker-based CLI that generates an API key and registers a new user in DynamoDB.
- **S3** — stores the transferred files; 1-day lifecycle expiration.
- **DynamoDB** — stores users (hashed API key, quotas, counters).
- **API Gateway** — HTTP API with throttling and a CloudWatch alarm on traffic bursts.

## Example usage

![Example usage gif](docs/demo.gif)

More info about CLI tool itself -> [Netpipe](https://github.com/b-zago/netpipe)

## Trade-offs

- Monthly quota is checked and deducted when the presigned URL is issued, not when the transfer actually completes. If the client's upload or download fails on their end, the quota is still consumed.
  - For uploads this could be fixed by reconciling the quota from another Lambda triggered by S3 `ObjectCreated` events, using the actual object size instead of the declared one.
  - For downloads one option is enabling S3 server access logs (or CloudTrail S3 data events) and reconciling the quota from those asynchronously based on the bytes actually served.
  - Since this service is only meant to be used among friends, I deemed the extra complexity unnecessary. (for now)
