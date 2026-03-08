resource "aws_vpc" "shinjuku_vpc01" {
  cidr_block           = var.shinjuku_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  provider = aws.tokyo

  tags = {
    Name = "${local.shinjuku}-vpc"
  }
}