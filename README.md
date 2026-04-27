# terraforming

Terraform configuration for my personal AWS infra.

## Projects

- [netpipe](aws/netpipe/)

## Layout

### `aws/`

- **`shared/`** — resources applied globally across the account (e.g. budget alerts).
- **`modules/`** — reusable modules consumed by the projects.
- **`applications/`** — AWS Service Catalog AppRegistry entries, used to tag and group resources per project for easier organization.
- Any other folder under `aws/` is a standalone project. See [Projects](#projects) below.

### `localstack/`

Mirror of the AWS setup pointed at [LocalStack](https://www.localstack.cloud/) for local testing. Not used for anything else.

## Hooks

To have access to the pre-push cloud sync run `git config core.hooksPath .githooks` and in root create an `.env` file with according `PRIVATE_S3_BUCKET` variable.
