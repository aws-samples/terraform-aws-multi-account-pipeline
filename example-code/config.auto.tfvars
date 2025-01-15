// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# default variable management 

# config is used to reference specific values for each AWS account
# eg deploy a different cidr range to each AWS account
# use it with local.config
# # eg local.config.cidr

config = {
  "112233445566" = {
    owner = "alice"
    cidr  = "10.20.192.0/24"
  }

  "223344556677" = {
    owner = "bob"
    cidr  = "10.21.192.0/24"
  }

  "334455667788" = {
    owner = "eve"
    cidr  = "10.22.300.0/16"
  }

  # alternative referencing

  # "workload1" = {
  #   owner = "alice"
  #   cidr  = "10.20.192.0/24"
  # }

  # "workload2" = {
  #   owner = "bob"
  #   cidr  = "10.21.192.0/24"
  # }

  # "workload3" = {
  #   owner = "eve"
  #   cidr  = "10.22.300.0/16"
  # }

}
