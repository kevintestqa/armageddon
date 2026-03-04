locals { 
  shinjuku= "shinjuku"
}

resource "aws_route_table" "shinjuku_public_rt01" {
  vpc_id = aws_vpc.shinjuku_vpc01.id

  tags = {
    Name = "${local.shinjuku}-public-rt01"
  }
}

resource "aws_route_table_association" "chrisbarm_public_rta" {
  count          = length(aws_subnet.shinjuku_public_subnets)
  subnet_id      = aws_subnet.shinjuku_public_subnets[count.index].id
  route_table_id = aws_route_table.shinjuku_public_rt01.id
}






# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "shinjuku_private_rt01" {
  vpc_id = aws_vpc.shinjuku_vpc01.id

  tags = {
    Name = "${local.shinjuku}-private-rt01"
  }
}
# Explanation: Shinjuku returns traffic to Liberdade—because doctors need answers, not one-way tunnels.
resource "aws_route" "shinjuku_to_liberdade_route01" {
  route_table_id         = aws_route_table.shinjuku_private_rt01.id
  destination_cidr_block = var.liberdade_vpc # Sao Paulo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgw01.id
}
resource "aws_route_table_association" "shinjuku_private_rta" {
  count          = length(aws_subnet.liberdade_public_subnets)
  subnet_id      = aws_subnet.shinjuku_private_subnets[count.index]
  route_table_id = aws_route_table.shinjuku_private_rt01.id
}


