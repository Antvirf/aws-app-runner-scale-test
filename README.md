# AWS App Runner scale test

The purpose of this repository is to create a simple container image that can be used to test the scaling capabilities of AWS App Runner, specifically the speed at which it can respond to spiky loads.

```bash
make buildc     # build container locally
make runc       # run container locally

make infra      # create infrastructure
make loadtest   # run load test script
```

## Infrastructure

The infrastructure required to run this is created with Terraform in the [infra](./infra/) folder. It creates the following resources:

- ECR to push the container image to (as at the time of writing App Runner only supports ECR as a source for container images)
- IAM role to access the ECR repository
- IAM user who is assigned the ECR access role
- IAM user access key for auth with GitHub Actions for the container build and push flow
- App Runner scaling config resource
- App Runner service resource


The first apply of this code will fail, as you will create an ECR that has no images in it. After the initial apply, push an image to the ECR, update the image App Runner is looking for, and reapply to get the service up.

In order to execute the Terraform code,  you will need to configure the AWS provider with:

```hcl
provider "aws" {
  region  = "ap-southeast-1" # your desired AWS region
  profile = "000000000000_Administrator" # your desired AWS CLI profile
}
```

## Test application

The test app is a [simple Go application](./test-app/main.go) that responds to HTTP requests with a configurable delay, defaulting to 80 ms. It is built with GitHub Actions and pushed to ECR.

## Load tests

Load tests will be done with [K6](https://github.com/grafana/k6), and monitored with Cloud Watch. The load test script is [here](./loadtests/main.js).

Test specifics WIP

## Results

WIP
