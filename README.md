# multi-account-pipeline

Deploy terraform to multiple AWS accounts. 

## Prerequisites
- An existing AWS CodeCommit repository ("your repo"); *or*
- An existing [AWS CodeConnection connection](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html) to the third-party source of your choice (GitHub, Gitlab, etc)
- [Remote state](https://developer.hashicorp.com/terraform/language/state/remote) that the pipeline can access (using the codebuild execution IAM role)
- A cross-account IAM role in the target accounts, that can be assumed by the pipeline

## Deployment

This module must be deployed to a separate repository.

```
your repo
   README.md
   backend.tf 
   main.tf
   variables.tf    

pipeline repo 
   main.tf <--module deployed here
```

Segregation enables the pipeline to run commands against the code in "your repo" without affecting the pipeline infrastructure. Typically this could be an infrastructure or bootstrap repo for the AWS account thats used to provision infrastructure and/or multiple pipelines.

## Module inputs
AWS CodeCommit: 
```hcl
module "pipeline" {
  source        = ""
  pipeline_name = ""
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
  source        = ""
  pipeline_name = ""
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

`connection` is the connection arn of the [connection](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html) to the third-party repo. 

### Optional inputs

```hcl
module "pipeline" {
  ...
  branch                = "main"
  detect_changes        = true
  kms_key               = aws_kms_key.this.arn
  access_logging_bucket = aws_s3_bucket.this.id

  environment_variables = {
    TF_VERSION     = "1.5.7"
    TFLINT_VERSION = "0.33.0"
  }

  checkov_skip = [
    "CKV_AWS_144", #Ensure that S3 bucket has cross-region replication enabled
  ]

}
```

`branch` is the CodeCommit branch. It defaults to "main" and may need to be altered if you are using pre-commit hooks that default to "master". 

`detect_changes` is used with third-party services, like GitHub. It enables AWS CodeConnections to invoke the pipeline when there is a commit to the repo.  

`kms_key` is the arn of an *existing* AWS KMS key. This input will encrypt the Amazon S3 bucket with a AWS KMS key of your choice. Otherwise the bucket will be encrypted using SSE-S3. Your AWS KMS key policy will need to allow codebuild and codepipeline to `kms:GenerateDataKey*` and `kms:Decrypt`. 

`environment_variables` can be used to define terraform and [tf_lint](https://github.com/terraform-linters/tflint) versions. 

`checkov_skip` defines [Checkov](https://www.checkov.io/) skips for the pipeline. This is useful for organization-wide policies, removing the need to add individual resource skips. 

## Architecture

![image info](./img/architecture.png)

1. **(1a)** User commits to a third-party repository, this invokes the AWS Codepipeline pipeline; *or* **(1b)** User commits to a CodeCommit repository, this invokes an Amazon EventBridge rule, which runs the pipeline. 
2. The pipeline validates the code and then runs a terraform plan against all of the target AWS accounts. Manual approval is then required to run the terraform apply. 
3. Resources are deployed to the target AWS accounts using [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces). Each AWS account is assigned their own Workspace using their AWS Account ID. 
4. Artifacts and logs are exported to Amazon S3 and CloudWatch logs.


## Troubleshooting

| Issue | Fix |
|---|---|
| Failed lint or validate | Read the report or logs to discover why the code has failed, then make a new commit. |
| Failed fmt | This means your code is not formatted. Run `terraform fmt --recursive` on your code, then make a new commit. |
| Failed SAST | Read the Checkov logs (Details > Reports) and either make the correction in code or add a skip to the module inputs. |
| Failed plan or apply stage | Read the report or logs to discover error in terraform code, then make a new commit. |
| Pipeline fails on apply with `the action failed because no branch named main was found ...` | Either nothing has been committed to the repo or the branch is incorrect (Eg using `Master` not `Main`). Either commit to the Main branch or change the module input to fix this. |
| `Invalid count argument` for `aws_s3_bucket_server_side_encryption_configuration` | The AWS KMS key must exist before the pipeline is created. If you create both at the same time, there is a dependency issue. |
| Unable to find state file | Check state storage :env > AWS Account ID > backend key |


## Best Practices

The CodeBuild execution role is highly privileged as this pattern is designed for a wide audience to deploy any resource to an AWS account. It assumes there are strong organizational controls in place and good segregation practices at the AWS account level. 

Permissions to your CodeCommit repository, CodeBuild projects, and CodePipeline pipeline should be tightly controlled. Here are some ideas:
- [Specify approval permission for specific pipelines and approval actions](https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals-iam-permissions.html#approvals-iam-permissions-limited).
- [Using identity-based policies for AWS CodeBuild](https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html). 
- [Limit pushes and merges to branches in AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-conditional-branch.html)

Checkov skips can be used where Checkov policies conflict with your organization's practices or design decisions. The `checkov_skip` module input allows you to set skips for all resources in your repository. For example, if your organization operates in a single region you may want to add `CKV_AWS_144` (Ensure that S3 bucket has cross-region replication enabled). For individual resource skips, you can still use [inline code comments](https://www.checkov.io/2.Basics/Suppressing%20and%20Skipping%20Policies.html).

## Related Resources

- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
- [Resource: aws_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/repository)
- [Resource: aws_codebuild_project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project)
- [Resource: aws_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
