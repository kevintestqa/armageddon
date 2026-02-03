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

# Explanation: Private subnets are the hidden Rebel base—no direct access from the internet.
resource "aws_subnet" "shinjuku_private_subnets" {
  count             = length(var.shinjuku_private_cidrs)
  vpc_id            = aws_vpc.shinjuku_vpc01.id
  cidr_block        = var.shinjuku_private_cidrs[count.index]
  availability_zone = var.shinjuku_az[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.shinjuku}-private-subnet0${count.index + 1}"
  }
}