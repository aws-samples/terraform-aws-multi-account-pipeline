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

variable "tags" {
  description = "tags to check for"
  type        = string
  default     = ""
}

variable "tagnag_version" {
  type    = string
  default = "0.5.8"
}

variable "terraform_version" {
  type    = string
  default = "1.5.7"
}

variable "tflint_version" {
  type    = string
  default = "0.48.0"
}

variable "workspace_directory" {
  type    = string
  default = ""
}
