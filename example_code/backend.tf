// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

terraform {
  backend "s3" {
    bucket         = ""
    key            = "<key>/terraform.tfstate"
    region         = ""
    encrypt        = true
    dynamodb_table = ""
  }
}
