locals { 
  sao_paulo = "liberdade"
}

# Explanation: Liberdade knows the way to Shinjuku—Tokyo CIDR routes go through the TGW corridor.
resource "aws_route" "liberdade_to_tokyo_route01" {
  provider               = aws.saopaulo
  route_table_id         = aws_route_table.liberdade_private_rt01.id
  destination_cidr_block = var.shinjuku_vpc # Tokyo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
}

resource "aws_route_table_association" "liberdade_public_rta" {
  count          = length(aws_subnet.liberdade_public_subnets)
  subnet_id      = aws_subnet.liberdade_public_subnets[count.index].id
  route_table_id = aws_route_table.liberdade_private_rt01.id
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "liberdade_private_rt01" {
  vpc_id = aws_vpc.liberdadee_vpc01.id

  tags = {
    Name = "${local.sao_paulo}-private-rt01"
  }
}