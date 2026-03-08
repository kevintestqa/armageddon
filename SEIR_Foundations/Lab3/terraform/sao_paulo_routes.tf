locals {
  sao_paulo = "liberdade"
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "liberdade_private_rt01" {
  vpc_id   = aws_vpc.liberdade_vpc01.id
  provider = aws.sao_paulo

  tags = {
    Name = "${local.sao_paulo}-private-rt01"
  }
}

resource "aws_route_table" "liberdade_public_rt01" {
  vpc_id   = aws_vpc.liberdade_vpc01.id
  provider = aws.sao_paulo

  tags = {
    Name = "${local.sao_paulo}-public-rt01"
  }
}

# Explanation: Liberdade knows the way to Shinjuku—Tokyo CIDR routes go through the TGW corridor.
resource "aws_route" "liberdade_to_tokyo_route01" {
  provider               = aws.sao_paulo
  route_table_id         = aws_route_table.liberdade_private_rt01.id
  destination_cidr_block = var.shinjuku_vpc # Tokyo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
}

resource "aws_route_table_association" "liberdade_public_rta" {
  count          = length(aws_subnet.liberdade_public_subnets)
  subnet_id      = aws_subnet.liberdade_public_subnets[count.index].id
  route_table_id = aws_route_table.liberdade_public_rt01.id
  provider       = aws.sao_paulo
}

resource "aws_route_table_association" "liberdade_private_rta" {
  count          = length(aws_subnet.liberdade_private_subnets)
  subnet_id      = aws_subnet.liberdade_private_subnets[count.index].id
  route_table_id = aws_route_table.liberdade_private_rt01.id
  provider       = aws.sao_paulo
}

resource "aws_route" "liberdade_public_default_route01" {
  route_table_id         = aws_route_table.liberdade_public_rt01.id
  destination_cidr_block = local.all_ip_address
  gateway_id             = aws_internet_gateway.liberdade_igw01.id
  provider               = aws.sao_paulo
}