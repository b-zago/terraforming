# terraforming

Terraform configuration for my personal AWS infra.

## Projects

- [nyanwatch](./aws/nyanwatch) - checks status of my workloads running in [k3s-cluster](github.com/b-zago/k3s-cluster) and notifies on discord accordingly.
- [netpipe](aws/netpipe/) [DEPRACATED - NEEDS REFACTOR] - download/upload with s3 on presigned URLs with own user validation on API requests.

## Layout

### `aws/`

- **`shared/`** — resources applied globally across the account (e.g. budget alerts).
- **`modules/`** — reusable modules consumed by the projects.
- **`applications/`** — AWS Service Catalog AppRegistry entries, used to tag and group resources per project for easier organization.
- Any other folder under `aws/` is a standalone project. See [Projects](#projects) below.

## Hooks

To have access to the pre-push cloud sync run `git config core.hooksPath .githooks` and in root create an `.env` file with according `PRIVATE_S3_BUCKET` variable. THis will upload all .tfvars and .tfstate files to the private s3.

To download those files after cloning this repo (or just to sync with s3) you can use `state-sync.sh`
