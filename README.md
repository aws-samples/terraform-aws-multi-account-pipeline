# terraform-aws-multi-account-pipeline

Deploy terraform to multiple AWS accounts.

(If you want to deploy a single AWS account use [aws-terraform-pipeline](https://github.com/aws-samples/aws-terraform-pipeline))

## Prerequisites
1. An existing AWS CodeCommit repository *OR* an [AWS CodeConnection connection](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html) to the third-party source and repo of your choice (GitHub, Gitlab, etc)
2. [Remote state](https://developer.hashicorp.com/terraform/language/state/remote) that the pipeline can access (using the CodeBuild IAM role)
3. A cross-account IAM role in the target accounts, that can be assumed by the pipeline (using the CodeBuild IAM Role).  
4. (Optional) Your code must be compatible with the pipeline's use of [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces) if you wish to change variables between accounts. Review the [example code directory](./example-code) and ensure your code is compatible. 
 
## Deployment

This module must be deployed to a separate repository. 

```
your repo
   modules
   backend.tf 
   config.auto.tfvars
   locals.tf 
   main.tf
   provider.tf
   variables.tf

pipeline repo 
   main.tf <--module deployed here
```

Segregation enables the pipeline to run commands against the code in "your repo" without affecting the pipeline infrastructure. 

Review the [example code directory](./example-code) and ensure the code in your repo is compatible. 

## Module Inputs
AWS CodeCommit: 
```hcl
module "pipeline" {
  source        = "aws-samples/multi-account-pipeline/aws"
  version       = "1.6.x"
  pipeline_name = "pipeline"
  repo          = aws_repository.this.repository_name
  accounts      = {
    "workload1" = "112233445566"
    "workload2" = "223344556677"
    "workload3" = "334455667788"
  }
}
```
Third-party service:
```hcl
module "pipeline" {
  source        = "aws-samples/multi-account-pipeline/aws"
  version       = "1.6.x"
  pipeline_name = "pipeline"
  repo          = "organization/repo"
  connection    = aws_codestarconnections_connection.this.arn
  accounts      = {
    "workload1" = "112233445566"
    "workload2" = "223344556677"
    "workload3" = "334455667788"
  }
}
```

`pipeline_name` is used to name the pipeline and prefix other resources created, like IAM roles. 

`repo` is the name of your existing repo that the pipeline will use as a source. If you are using a third-party service, the format is "my-organization/repo"  

`accounts` is a map of the target AWS accounts. 

`connection` is the connection arn of the [connection](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html) to the third-party repo. 

### Optional Inputs

```hcl
module "pipeline" {
  ...
  branch                = "main"
  deployment_type       = "parallel"
  mode                  = "SUPERSEDED"
  detect_changes        = false
  kms_key               = aws_kms_key.this.arn
  access_logging_bucket = aws_s3_bucket.this.id
  artifact_retention    = 90

  workspace_directory = "workspaces"

  codebuild_policy  = aws_iam_policy.this.arn
  build_timeout     = 10
  terraform_version = "1.8.0"
  checkov_version   = "3.2.0"
  tflint_version    = "0.55.0"

  build_override = {
    directory       - "./terraform" 
    plan_buildspec  = file("./my_plan.yml")
    plan_image      = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    apply_buildspec = file("./my_apply.yml")
    apply_image     = "hashicorp/terraform:latest"
  }

  vpc = {
    vpc_id             = "vpc-011a22334455bb66c",
    subnets            = ["subnet-011aabbcc2233d4ef"],
    security_group_ids = ["sg-001abcd2233ee4455"],
  }

  notifications = {
    sns_topic   = aws_sns_topic.this.arn
    detail_type = "BASIC"
    events = [
      "codepipeline-pipeline-pipeline-execution-failed",
      "codepipeline-pipeline-pipeline-execution-succeeded"
    ]
  }

  tags = join(",", [
    "Environment[Dev,Prod]",
    "Source"
  ])
  tagnag_version = "0.7.9"

  checkov_skip = [
    "CKV_AWS_144", #Ensure that S3 bucket has cross-region replication enabled
  ]
}
```

See [optional inputs](./docs/optional_inputs.md) for descriptions.

##  Docs

- [Optional inputs](./docs/optional_inputs.md)
- [Architecture](./docs/architecture.md)
- [Troubleshooting](./docs/troubleshooting.md)
- [Best practices](./docs/best_practices.md) 

## Related Resources

- [aws-terraform-pipeline](https://github.com/aws-samples/aws-terraform-pipeline)
- [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [Terraform Registry: aws-samples/multi-account-pipeline/aws](https://registry.terraform.io/modules/aws-samples/multi-account-pipeline/aws/latest)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

