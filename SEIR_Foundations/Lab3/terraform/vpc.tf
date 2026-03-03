resource "aws_vpc" "liberdade_vpc01" {
  cidr_block           = var.liberdade_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.liberdade}-vpc"
  }
}

resource "aws_vpc" "shinjuku_vpc01" {
  cidr_block           = var.shinjuku_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.shinjuku}-vpc"
  }
}