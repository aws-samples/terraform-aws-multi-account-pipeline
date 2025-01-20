// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_codepipeline" "this" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline.arn

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
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = var.repo
        BranchName           = var.branch
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Validation"

    dynamic "action" {
      for_each = local.validation_stages
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

  stage {
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

        configuration = {
          ProjectName = module.plan.codebuild_project.name
          EnvironmentVariables = jsonencode([
            {
              name  = "WORKSPACE"
              value = action.value
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

  stage {
    name = "Approval"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "This action will approve the deployment of resources. Please ensure that you review the build logs of the plan stage before approving."
      }
    }
  }

  stage {
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

        configuration = {
          ProjectName = module.apply[action.key].codebuild_project.name
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
      "codecommit:CancelUploadArchive"
    ]

    resources = [
      "arn:aws:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.repo}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = [
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-*"
    ]
  }

}
