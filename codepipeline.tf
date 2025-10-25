// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_codepipeline" "this" {
  name           = var.pipeline_name
  pipeline_type  = "V2"
  role_arn       = aws_iam_role.codepipeline.arn
  execution_mode = var.mode

  artifact_store {
    location = aws_s3_bucket.this.id
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = var.connection == null ? "CodeCommit" : "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName       = var.connection == null ? var.repo : null
        FullRepositoryId     = var.connection == null ? null : var.repo
        ConnectionArn        = var.connection
        BranchName           = var.branch
        PollForSourceChanges = var.connection == null ? false : null
        DetectChanges        = var.connection == null ? null : var.detect_changes
      }
    }
  }

  stage {
    name = "Validation"
    dynamic "action" {
      for_each = var.tags == "" ? local.validation_stages : local.conditional_validation_stages
      content {
        name            = action.key
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["source_output"]
        version         = "1"
        configuration = {
          ProjectName = module.validation[action.key].codebuild_project.name
        }
      }
    }
  }

  // parallel
  dynamic "stage" {
    for_each = length(var.sequential) == 0 ? ["plan"] : []
    content {
      name = "Plan"
      dynamic "action" {
        for_each = var.accounts
        content {
          name            = action.key
          category        = "Build"
          owner           = "AWS"
          provider        = "CodeBuild"
          input_artifacts = ["source_output"]
          version         = "1"
          run_order       = 1
          configuration = {
            ProjectName = module.plan.codebuild_project.name
            EnvironmentVariables = jsonencode([
              {
                name  = "WORKSPACE"
                value = action.value
                type  = "PLAINTEXT"
              },
              {
                name  = "ACCOUNT_NAME"
                value = action.key
                type  = "PLAINTEXT"
              },
              {
                name  = "TF_VAR_account_id"
                value = action.value
                type  = "PLAINTEXT"
              },
              {
                name  = "TF_VAR_account_name"
                value = action.key
                type  = "PLAINTEXT"
            }])
          }
        }
      }
      action {
        name      = "Approval"
        category  = "Approval"
        owner     = "AWS"
        provider  = "Manual"
        version   = "1"
        run_order = 2
        configuration = {
          CustomData = "This action will approve the deployment of resources in ${var.pipeline_name}. Please review the plan action before approving."
        }
      }
    }
  }
  dynamic "stage" {
    for_each = length(var.sequential) == 0 ? ["apply"] : []
    content {
      name = "Apply"
      dynamic "action" {
        for_each = var.accounts
        content {
          name            = action.key
          category        = "Build"
          owner           = "AWS"
          provider        = "CodeBuild"
          input_artifacts = ["source_output"]
          version         = "1"
          run_order       = 1
          configuration = {
            ProjectName = module.apply.codebuild_project.name
            EnvironmentVariables = jsonencode([
              {
                name  = "WORKSPACE"
                value = action.value
                type  = "PLAINTEXT"
              },
              {
                name  = "ACCOUNT_NAME"
                value = action.key
                type  = "PLAINTEXT"
              },
              {
                name  = "TF_VAR_account_id"
                value = action.value
                type  = "PLAINTEXT"
              },
              {
                name  = "TF_VAR_account_name"
                value = action.key
                type  = "PLAINTEXT"
            }])
          }
        }
      }
    }
  }

  // sequential
  dynamic "stage" {
    for_each = length(var.sequential) > 0 ? local.ordered_accounts : {}
    content {
      name = stage.key

      action {
        name            = "Plan"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["source_output"]
        version         = "1"
        run_order       = 1
        configuration = {
          ProjectName = module.plan.codebuild_project.name
          EnvironmentVariables = jsonencode([
            {
              name  = "WORKSPACE"
              value = stage.value
              type  = "PLAINTEXT"
            },
            {
              name  = "ACCOUNT_NAME"
              value = stage.key
              type  = "PLAINTEXT"
            },
            {
              name  = "TF_VAR_account_id"
              value = stage.value
              type  = "PLAINTEXT"
            },
            {
              name  = "TF_VAR_account_name"
              value = stage.key
              type  = "PLAINTEXT"
          }])
        }
      }

      action {
        name      = "Approval"
        category  = "Approval"
        owner     = "AWS"
        provider  = "Manual"
        version   = "1"
        run_order = 2
        configuration = {
          CustomData = "This action will approve the deployment of resources in ${var.pipeline_name}. Please review the plan action before approving."
        }
      }

      action {
        name            = "Apply"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["source_output"]
        version         = "1"
        run_order       = 3
        configuration = {
          ProjectName = module.apply.codebuild_project.name
          EnvironmentVariables = jsonencode([
            {
              name  = "WORKSPACE"
              value = stage.value
              type  = "PLAINTEXT"
            },
            {
              name  = "ACCOUNT_NAME"
              value = stage.key
              type  = "PLAINTEXT"
            },
            {
              name  = "TF_VAR_account_id"
              value = stage.value
              type  = "PLAINTEXT"
            },
            {
              name  = "TF_VAR_account_name"
              value = stage.key
              type  = "PLAINTEXT"
          }])
        }
      }
    }
  }

}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.pipeline_name}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:codepipeline:${local.region}:${data.aws_caller_identity.current.account_id}:${var.pipeline_name}"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_iam_policy" "codepipeline" {
  name   = "${var.pipeline_name}-codepipeline"
  policy = data.aws_iam_policy_document.codepipeline.json
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.this.arn}",
      "${aws_s3_bucket.this.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive",
      "codestar-connections:UseConnection"
    ]
    resources = [
      var.connection == null ? "arn:aws:codecommit:${local.region}:${data.aws_caller_identity.current.account_id}:${var.repo}" : var.connection
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      "arn:aws:codebuild:${local.region}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-*"
    ]
  }
}

resource "aws_codestarnotifications_notification_rule" "this" {
  count          = var.notifications != null ? 1 : 0
  name           = var.pipeline_name
  detail_type    = var.notifications["detail_type"]
  event_type_ids = var.notifications["events"]
  resource       = aws_codepipeline.this.arn

  target {
    address = var.notifications["sns_topic"]
  }
}
