// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "accounts" {
  description = "AWS account names and IDs"
  type        = map(string)
}

variable "pipeline_name" {
  type = string
}

variable "repo" {
  description = "source repo name"
  type        = string
}

// optional

variable "access_logging_bucket" {
  description = "s3 server access logging bucket arn"
  default     = null
}

variable "artifact_retention" {
  description = "s3 artifact bucket retention, in days"
  type        = number
  default     = 90
}

variable "branch" {
  type    = string
  default = "main"
}

variable "build_override" {
  description = "Override CodeBuild images and buildspecs"
  type = object({
    directory       = optional(string, ".")
    plan_buildspec  = optional(string)
    plan_image      = optional(string)
    apply_buildspec = optional(string)
    apply_image     = optional(string)
  })
  default = {}
}

variable "build_timeout" {
  description = "CodeBuild project build timeout"
  type        = number
  default     = 10
}

variable "connection" {
  description = "arn of the CodeConnection"
  type        = string
  default     = null
}

variable "checkov_skip" {
  description = "list of checkov checks to skip"
  type        = list(string)
  default     = [""]
}

variable "checkov_version" {
  type    = string
  default = "3.2.0"
}

variable "codebuild_policy" {
  description = "replaces CodeBuild's AWSAdministratorAccess IAM policy"
  type        = string
  default     = null
}

variable "detect_changes" {
  description = "allows third-party servicesm like GitHub to invoke the pipeline"
  type        = bool
  default     = false
}

variable "kms_key" {
  description = "AWS KMS key ARN"
  type        = string
  default     = null
}

variable "log_retention" {
  description = "CloudWatch log group retention, in days"
  type        = number
  default     = 90
}

variable "mode" {
  description = "pipeline execution mode"
  type        = string
  default     = "SUPERSEDED"
  validation {
    condition = contains([
      "SUPERSEDED",
      "PARALLEL",
      "QUEUED"
    ], var.mode)
    error_message = "unsupported pipeline mode"
  }
}

variable "notifications" {
  description = "SNS notification configuration"
  type = object({
    sns_topic   = string
    events      = list(string)
    detail_type = string
  })
  default = null
}

variable "sequential" {
  description = ""
  type        = bool
  default     = false
}

variable "tags" {
  description = "tags to check for"
  type        = string
  default     = ""
}

variable "tagnag_version" {
  type    = string
  default = "0.7.9"
}

variable "terraform_version" {
  type    = string
  default = "1.8.0"
}

variable "tflint_version" {
  type    = string
  default = "0.55.0"
}

variable "workspace_directory" {
  type    = string
  default = ""
}

variable "vpc" {
  type = object({
    vpc_id             = string
    subnets            = list(string)
    security_group_ids = list(string)
  })
  default = null
}
