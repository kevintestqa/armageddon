resource "aws_internet_gateway" "shinjuku_igw01" {
  vpc_id = aws_vpc.shinjuku_vpc01.id

  tags = {
    Name = "${local.shinjuku}-igw01"
  }
}