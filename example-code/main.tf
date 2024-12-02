// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# simple parameters

resource "aws_s3_bucket" "foo" {
  bucket = "bucket-${var.account_id}"
}

resource "aws_s3_bucket" "bar" {
  bucket = "bucket-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "baz" {
  bucket = "bucket-${var.account_name}"
}


# complex parameters

resource "aws_route_table" "this" {
  vpc_id = "vpc"

  route {
    cidr_block = local.config.cidr
    gateway_id = "local"
  }

  tags = {
    Owner = local.config.owner
  }
}

# conditionals

resource "aws_s3_bucket" "that" {
  count  = var.account_id == "112233445566" ? 1 : 0
  bucket = "conditional-bucket-${var.account_id}"
}

