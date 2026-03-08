# Explanation: Even Wookiees need to reach the wider galaxy—IGW is your door to the public internet.
resource "aws_internet_gateway" "liberdade_igw01" {
  vpc_id   = aws_vpc.liberdade_vpc01.id
  provider = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-igw01"
  }
}

############################################
# NAT Gateway + EIP
############################################

resource "aws_eip" "sao_paulo_satellite_nat_eip01" {
  domain   = "vpc"
  provider = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-nat-eip01"
  }
}

resource "aws_nat_gateway" "sao_paulo_satellite_nat01" {
  allocation_id = aws_eip.sao_paulo_satellite_nat_eip01.id
  subnet_id     = aws_subnet.liberdade_public_subnets[0].id # NAT in a public subnet
  provider      = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-nat01"
  }

  depends_on = [aws_internet_gateway.liberdade_igw01]
}