resource "aws_vpc" "liberdade_vpc01" {
  cidr_block           = var.liberdade_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  provider             = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-vpc01"
  }
}

resource "aws_vpc" "shinjuku_vpc01" {
  cidr_block           = var.shinjuku_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  provider             = aws.tokyo

  tags = {
    Name = "${local.shinjuku}-vpc"
  }
}