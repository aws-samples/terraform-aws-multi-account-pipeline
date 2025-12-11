// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = "~> 1.1"
}

provider "aws" {
  region = ""
  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/sandbox-cross-account"
    session_name = "sdmp"
  }
}
