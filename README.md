# terraforming

Terraform for my personal AWS account: reusable modules, account-wide guardrails, and the AWS side of my projects, including serverless monitoring for my Kubernetes platform and the identity setup that lets my self-hosted clusters and GitHub Actions use AWS without stored credentials.

## Highlights

- **No long-lived AWS keys.** GitHub Actions deploys through GitHub's OIDC provider, with IAM roles that trust only a specific repository and branch. My self-hosted k3s clusters authenticate the same way through their own OIDC issuers (see [box](https://github.com/b-zago/box)).
- **Account guardrails.** A monthly budget with alerts, EBS encryption by default, ECR image scanning, blocked public access on S3, and versioned remote state.
- **Reusable modules.** ECR, Lambda, EventBridge Scheduler, VPC and the cluster OIDC setup are modules; each project is a small root that composes them.
- **Serverless projects.** An uptime monitor running every minute (Lambda, EventBridge Scheduler, DynamoDB), and a file transfer service with API keys and quotas (API Gateway, Lambda authorizer, presigned S3 URLs).

## Contents

- [Layout](#layout)
- [Modules](#modules)
- [Projects](#projects)
- [Account guardrails](#account-guardrails)
- [State and variables](#state-and-variables)

## Layout

```
aws/
  shared/         Account-wide resources: budget, S3 buckets, OIDC providers, defaults
  modules/        Reusable modules
  nyanwatch/      Uptime monitor for my apps
  dev/            Test environment (VPC, EC2) used to develop the Proxmox host setup
  applications/   AWS AppRegistry applications that group resources per project
old/
  netpipe/        File transfer service (earlier project, uses an older Lambda module)
```

Every folder under `aws/` except `modules/` is its own Terraform root with its own state.

## Modules

| Module             | What it creates                                                                                                                                                                                                                                           |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ecr`              | An ECR repository with lifecycle rules and a repository policy, plus an optional IAM role for GitHub Actions that trusts only the matching GitHub repository and selected branches. It can push images and, optionally, update the Lambda that uses them. |
| `lambdav2`         | A container- or zip-based Lambda function with its execution role, permissions passed in as a map, and a CloudWatch log group with retention.                                                                                                             |
| `scheduler`        | An EventBridge Scheduler schedule with the IAM role it needs to invoke its target.                                                                                                                                                                        |
| `vpc`              | A VPC with public and private subnets and routing. A NAT gateway is added when private subnets are defined.                                                                                                                                               |
| `oidc_provisioner` | An IAM OIDC provider for a self-hosted Kubernetes cluster and one IAM role per service account, each limited to specific SSM parameter paths. Used by [box](https://github.com/b-zago/box) so that External Secrets can read SSM without access keys.     |

## Projects

### nyanwatch

Checks every minute whether my applications are up and sends me a Discord message when one goes down or recovers.

- **EventBridge Scheduler** invokes a **Lambda** function every minute.
- The function reads the list of endpoints from **SSM Parameter Store** (managed here from `endpoints.json`) and checks each one.
- **DynamoDB** remembers which services were failing, so alerts are sent only on a status change, not on every run.
- Notifications go through [nyanify](https://github.com/b-zago/nyanify), my service for Discord DMs.

Running it on AWS keeps the monitor outside the clusters it watches, so it still reports when the whole platform is down. The function's code lives in [nyanwatch](https://github.com/b-zago/nyanwatch) and is deployed by my [build-push-ecr-lambda workflow](https://github.com/b-zago/actions/blob/main/.github/workflows/build-push-ecr-lambda.yml). See [aws/nyanwatch](./aws/nyanwatch) for a diagram.

### netpipe

A small file transfer service: clients upload and download files through presigned S3 URLs, authenticated by an API key, with daily request limits and monthly transfer quotas per user. The declared file size is part of the presigned URL's conditions, so S3 rejects uploads that don't match it and clients can't get around their quota. It's an earlier project, kept in `old/` because it uses an older Lambda module. See [old/netpipe](./old/netpipe) for a diagram and a demo.

### dev

A disposable test environment: a VPC and an EC2 instance with nested virtualization, where I developed and tested the Ansible playbook that installs Proxmox for [box](https://github.com/b-zago/box). SSH and WireGuard are only allowed from my own address range. The instance is commented out when not in use.

## Account guardrails

`aws/shared` holds the resources that apply to the whole account:

- **Budget:** a monthly limit of 5 USD, with email alerts at 80% and 100% of actual spend and at 100% of forecast spend.
- **S3:** a private, versioned bucket for Terraform state and variables, with public access blocked; and a resources bucket where only the `oidc/` prefix is publicly readable (AWS must fetch the clusters' OIDC documents from there) and every request must use TLS.
- **Defaults:** EBS encryption on by default, ECR scanning for pushed images.
- **Identity:** the GitHub Actions OIDC provider that project roles trust.

## State and variables

Each root uses an S3 backend, configured through a git-ignored `backend.hcl`:

```sh
terraform -chdir=aws/nyanwatch init -backend-config=backend.hcl
terraform -chdir=aws/nyanwatch apply
```

Variable files (`*.tfvars`) stay out of Git. A pre-push hook copies them, along with any plan files, to the private bucket, and `state-sync.sh` downloads them on a new machine. To enable the hook, run `git config core.hooksPath .githooks` and set `PRIVATE_S3_BUCKET` in a root `.env` file.
