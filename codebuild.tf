// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

module "validation" {
  for_each              = var.tags == "" ? local.validation_stages : local.conditional_validation_stages
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-${each.key}"
  codebuild_role        = aws_iam_role.codebuild.arn
  environment_variables = var.tags == "" ? local.env_var : local.conditional_env_var
  build_timeout         = var.build_timeout
  build_spec            = "${each.key}.yml"
  log_group             = aws_cloudwatch_log_group.this.name
  image                 = each.value
  vpc                   = var.vpc
}

module "plan" {
  source                = "./modules/codebuild"
  codebuild_name        = lower("${var.pipeline_name}-plan")
  codebuild_role        = aws_iam_role.codebuild.arn
  environment_variables = local.env_var
  build_timeout         = var.build_timeout
  build_spec            = "plan.yml"
  log_group             = aws_cloudwatch_log_group.this.name
  image                 = "hashicorp/terraform:${var.terraform_version}"
  vpc                   = var.vpc
}

module "apply" {
  source                = "./modules/codebuild"
  codebuild_name        = lower("${var.pipeline_name}-apply")
  codebuild_role        = aws_iam_role.codebuild.arn
  environment_variables = local.env_var
  build_timeout         = var.build_timeout
  build_spec            = "apply.yml"
  log_group             = aws_cloudwatch_log_group.this.name
  image                 = "hashicorp/terraform:${var.terraform_version}"
  vpc                   = var.vpc
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.pipeline_name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-*"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = var.codebuild_policy == null ? aws_iam_policy.codebuild.arn : var.codebuild_policy
}

resource "aws_iam_policy" "codebuild" {
  name   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild.json
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases"
    ]
    resources = [
      aws_codebuild_report_group.sast.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "*" // for s3 backend
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "*" // for s3 backend
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = [
      "*"
    ]
  }

  // https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html#customer-managed-policies-example-create-vpc-network-interface
  dynamic "statement" {
    for_each = var.vpc == null ? [] : [var.vpc]
    content {
      effect = "Allow"
      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ]
      resources = [
        "*"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.vpc == null ? [] : [var.vpc]
    content {
      effect = "Allow"
      actions = [
        "ec2:CreateNetworkInterfacePermission"

      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "ec2:AuthorizedService"
        values = [
          "codebuild.amazonaws.com"
        ]
      }
      condition {
        test     = "ArnEquals"
        variable = "ec2:Subnet"
        values = [
          for id in var.vpc["subnets"] :
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${id}"
        ]
      }
    }
  }
}

resource "aws_codebuild_report_group" "sast" {
  name           = "sast-report-${var.pipeline_name}"
  type           = "TEST"
  delete_reports = true

  export_config {
    type = "S3"

    s3_destination {
      bucket              = aws_s3_bucket.this.id
      encryption_disabled = false
      encryption_key      = var.kms_key == null ? data.aws_kms_key.s3.arn : var.kms_key
      packaging           = "NONE"
      path                = "/sast"
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/codebuild/${var.pipeline_name}"
  retention_in_days = var.log_retention
  kms_key_id        = var.kms_key
}
