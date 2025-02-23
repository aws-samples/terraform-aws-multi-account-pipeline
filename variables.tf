// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "pipeline_name" {
  type = string
}

variable "repo" {
  type = string
}

variable "branch" {
  type    = string
  default = "main"
}

variable "environment_variables" {
  description = "environment variables for codebuild"
  type        = map(string)
  default = {
    TF_VERSION     = "1.5.7"
    TFLINT_VERSION = "0.48.0"
  }
}

variable "checkov_skip" {
  description = "list of checkov checks to skip"
  type        = list(string)
  default     = [""]
}

variable "accounts" {
  type = map(string)
}

variable "kms_key" {
  type    = string
  default = null
}

variable "access_logging_bucket" {
  description = "s3 server access logging bucket"
  default     = null
}

variable "connection" {
  type    = string
  default = null
}

variable "detect_changes" {
  type    = string
  default = false
}

variable "codebuild_policy" {
  type    = string
  default = null
}

variable "workspace_directory" {
  type    = string
  default = ""
}

variable "codebuild_timeout" {
  type    = number
  default = 60
}
