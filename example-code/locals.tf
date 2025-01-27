// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# default variable management

# local.config can be used to reference specific values for each AWS account
# eg local.config.cidr
# you can use account_id or account_name in config.auto.tfvars with the try function
locals {
  config = var.config[try(var.account_id, var.account_name)]

  # or just account_id or account_name

  #config = var.config[var.account_id]
  #config = var.config[var.account_name]
}

# remove the above if using workspaces directory
