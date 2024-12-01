// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  log_group = "/aws/${var.pipeline_name}"

  validation_stages = {
    validate = var.environment_variables,
    fmt      = var.environment_variables,
    lint     = var.environment_variables,
    sast = merge(tomap({
      SAST_REPORT_ARN = aws_codebuild_report_group.sast.arn
      }),
      var.environment_variables,
    )
  }
}


