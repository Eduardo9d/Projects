# Project Overview

This repository contains infrastructure automation, installation scripts, Kubernetes manifests, and a small network troubleshooting utility for an AWS-based environment.


## Diagram 

flowchart TD
    A[Start] --> B[Configure AWS credentials]
    B --> C[Run Terraform]
    C --> D{Terraform successful?}
    D -->|Yes| E[Install Kubernetes tools]
    E --> F[Deploy Kubernetes workloads]
    F --> G[Run network validation]
    G --> H[Ready]
    D -->|No| I[Troubleshoot]
    I --> J[Fix issue]
    J --> C


## Terraform

The `Terraform/` folder defines AWS infrastructure resources, including:

- `aws_vpc.main`: a VPC with DNS support enabled
- `aws_subnet.public`: a public subnet for EC2 resources
- `aws_internet_gateway.gw`: internet gateway for outbound access
- `aws_route_table.rt`: route table pointing to the IGW
- `aws_security_group.sg`: security group allowing SSH and Kubernetes API access
- `aws_instance.ec2`: EC2 instance configured with bootstrap user data for Kubernetes setup
- `aws_s3_bucket.bucket`: S3 bucket for storage or state artifacts

### Usage

1. Configure AWS credentials on your local machine.
2. Change variables in `Terraform/variables.tf` as needed.
3. Run from the `Terraform/` folder:
   - `terraform init`
   - `terraform plan`
   - `terraform apply`
4. To remove resources:
   - `terraform destroy`

> Note: The S3 bucket name must be globally unique.

## Bash

The `Bash/` folder contains installation scripts for the target environment:

- `Install_aws_cli.sh`: installs the AWS CLI tool
- `install_terraform.sh`: installs Terraform on a Linux host
- `install_kubernetes.sh`: prepares and installs Kubernetes dependencies on an EC2 instance

These scripts are intended to help bootstrap the EC2 host or local machine before running the Terraform-managed environment.

## Kubernetes

The `Kubernetes/` folder includes YAML manifests for deploying infrastructure components in a Kubernetes cluster:

- `install_apache.yaml`: deploys an Apache web server
- `install_PG_db.yaml`: deploys a PostgreSQL database service

These can be applied after the cluster is ready with `kubectl apply -f`.

## Python

The `Python/Network_test.py` script is a small troubleshooting utility for network issues with the EC2 instance.

### Purpose

- Validate connectivity to remote hosts
- Help diagnose AWS networking or cluster access problems

## Recommended workflow

1. Prepare AWS credentials and region.
2. Deploy infrastructure with Terraform.
3. Use the Bash scripts to install tools or configure nodes.
4. Deploy Kubernetes workloads from the `Kubernetes/` folder.
5. Use `Python/Network_test.py` to verify network connectivity.
