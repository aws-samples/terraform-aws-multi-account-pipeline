// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

module "validation" {
  for_each              = local.validation_stages
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-${each.key}"
  codebuild_role        = aws_iam_role.codebuild.arn
  environment_variables = each.value
  build_timeout         = 5
  build_spec            = "${each.key}.yml"
  log_group             = local.log_group
}

module "plan" {
  for_each       = var.accounts
  source         = "./modules/codebuild"
  codebuild_name = lower("${var.pipeline_name}-plan-${each.key}")
  codebuild_role = aws_iam_role.codebuild.arn
  environment_variables = merge(tomap({
    TF_VAR_account_name = each.key,
    TF_VAR_account_id   = each.value,
    WORKSPACE           = each.value,
    WORKSPACE_DIRECTORY = var.workspace_directory
    }),
    var.environment_variables
  )
  build_timeout = var.codebuild_timeout
  build_spec    = "plan.yml"
  log_group     = local.log_group
}

module "apply" {
  for_each       = var.accounts
  source         = "./modules/codebuild"
  codebuild_name = lower("${var.pipeline_name}-apply-${each.key}")
  codebuild_role = aws_iam_role.codebuild.arn
  environment_variables = merge(tomap({
    tf_var_account_name = each.key,
    tf_var_account_id   = each.value,
    workspace           = each.value
    workspace_directory = var.workspace_directory
    }),
    var.environment_variables
  )
  build_timeout = var.codebuild_timeout
  build_spec    = "apply.yml"
  log_group     = local.log_group
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
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group}",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group}:*"
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
      "*"
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
      "*"
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
      encryption_key      = try(var.kms_key, data.aws_kms_key.s3.arn)
      packaging           = "NONE"
      path                = "/sast"
    }
  }
}

