locals {
  liberdade = "liberdade"
  shinjuku = "shinjuku"
}

resource "aws_subnet" "liberdade_public_subnets" {
  count                   = length(var.liberdade_public_cidrs)
  vpc_id                  = aws_vpc.liberdadee_vpc01.id
  cidr_block              = var.liberdade_public_cidrs[count.index]
  availability_zone =       var.liberdade_az
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.liberdade}-public-subnet0${count.index + 1}"
  }
}

resource "aws_subnet" "liberdade_private_subnets" {
  count                   = length(var.liberdade_private_cidrs)
  vpc_id                  = aws_vpc.liberdadee_vpc01.id
  cidr_block              = var.liberdade_public_cidrs[count.index]
  availability_zone =       var.liberdade_az
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.liberdade}-private-subnet0${count.index + 1}"
  }
}
