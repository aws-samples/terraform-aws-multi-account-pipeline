// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# terraform will autopopulate these two variables using codebuild environment variables (TF_VAR) from your module inputs
variable "account_id" {
  type = string
}
variable "account_name" {
  type = string
}

# config is used to reference specific values for each AWS account
# eg deploy a different cidr range to each AWS account
# use it with local.config
# # eg local.config.cidr
variable "config" {
  description = "map of objects for per environment configuration"
  type = map(object({
    owner = string
    cidr  = string
  }))
}
