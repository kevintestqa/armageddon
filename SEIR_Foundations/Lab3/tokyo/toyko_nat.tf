resource "aws_eip" "shinjuku_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${local.shinjuku}-nat-eip01"
  }
}

resource "aws_nat_gateway" "shinjuku_nat01" {
  allocation_id = aws_eip.shinjuku_nat_eip01.id
  subnet_id     = aws_subnet.shinjuku_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.shinjuku}-nat01"
  }

  depends_on = [aws_internet_gateway.shinjuku_igw01]
}