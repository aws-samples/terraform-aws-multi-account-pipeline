// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  validation_stages = {
    validate = "hashicorp/terraform:${var.terraform_version}"
    fmt      = "hashicorp/terraform:${var.terraform_version}"
    lint     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    sast     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  }
  conditional_validation_stages = merge(local.validation_stages, {
    tags = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  })

  env_var = {
    TFLINT_VERSION      = var.tflint_version
    SAST_REPORT_ARN     = aws_codebuild_report_group.sast.arn
    CHECKOV_SKIPS       = join(",", "${var.checkov_skip}")
    WORKSPACE_DIRECTORY = var.workspace_directory
    TF_VERSION          = var.terraform_version
  }
  conditional_env_var = merge(local.env_var, {
    TAGS           = var.tags
    TAGNAG_VERSION = var.tagnag_version
  })
}
