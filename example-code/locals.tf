// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# local.config can be used to reference specific values for each AWS account
# eg local.config.cidr
locals {
  config = var.config[var.account_id]
}
