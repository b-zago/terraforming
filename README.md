# terraforming

Terraform configuration for my personal AWS infrastructure.

## Layout

### `aws/`

- **`shared/`** — resources applied globally across the account (e.g. budget alerts).
- **`modules/`** — reusable modules consumed by the projects.
- **`applications/`** — AWS Service Catalog AppRegistry entries, used to tag and group resources per project for easier organization.
- Any other folder under `aws/` is a standalone project. See [Projects](#projects) below.

## Projects

- [netpipe](aws/netpipe/)

### `localstack/`

Mirror of the AWS setup pointed at [LocalStack](https://www.localstack.cloud/) for local testing. Not used for anything else.
