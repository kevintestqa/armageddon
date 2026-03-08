resource "aws_internet_gateway" "shinjuku_igw01" {
  vpc_id = aws_vpc.shinjuku_vpc01.id
  provider = aws.tokyo

  tags = {
    Name = "${local.shinjuku}-igw01"
  }
}