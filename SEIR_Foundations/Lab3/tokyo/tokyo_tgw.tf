# Explanation: Shinjuku Station is the hub—Tokyo is the data authority.
resource "aws_ec2_transit_gateway" "shinjuku_tgw01" {
  description = "shinjuku-tgw01 (Tokyo hub)"
  provider    = aws.tokyo
  tags        = { Name = "shinjuku-tgw01" }
}

# Explanation: Create an explicit TGW route table so Tokyo forwarding is deterministic.
resource "aws_ec2_transit_gateway_route_table" "shinjuku_tgw_rt01" {
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw01.id
  provider           = aws.tokyo
  tags               = { Name = "shinjuku-tgw-rt01" }
}

# Explanation: Shinjuku connects to the Tokyo VPC—this is the gate to the medical records vault.
resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_attach_tokyo_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw01.id
  vpc_id             = aws_vpc.shinjuku_vpc01.id
  subnet_ids         = aws_subnet.shinjuku_private_subnets[*].id
  provider           = aws.tokyo
  tags               = { Name = "shinjuku-attach-tokyo-vpc01" }
}

# Explanation: Associate the Tokyo VPC attachment with the explicit Tokyo TGW route table.
resource "aws_ec2_transit_gateway_route_table_association" "shinjuku_vpc_assoc01" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shinjuku_attach_tokyo_vpc01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shinjuku_tgw_rt01.id
  provider                       = aws.tokyo
}

# Explanation: Shinjuku opens a corridor request to Liberdade—compute may travel, data may not.
resource "aws_ec2_transit_gateway_peering_attachment" "shinjuku_to_liberdade_peer01" {
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgw01.id
  peer_region             = "sa-east-1"
  peer_transit_gateway_id = var.liberdade_tgw_id
  provider                = aws.tokyo
  tags                    = { Name = "shinjuku-to-liberdade-peer01" }
}

# Explanation: Associate the peering attachment with the explicit Tokyo TGW route table.
resource "aws_ec2_transit_gateway_route_table_association" "shinjuku_peer_assoc01" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shinjuku_tgw_rt01.id
  provider                       = aws.tokyo
}

# Explanation: The Tokyo TGW route table must know that Liberdade's CIDR lives behind the peering attachment.
resource "aws_ec2_transit_gateway_route" "shinjuku_tgw_to_liberdade_route01" {
  destination_cidr_block         = var.liberdade_vpc
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shinjuku_tgw_rt01.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
  provider                       = aws.tokyo

    depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_shinjuku_peer01,
    aws_ec2_transit_gateway_route_table_association.shinjuku_peer_assoc01
  ]
}

#########
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_shinjuku_peer01" {
  provider                      = aws.sao_paulo
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
  tags                          = { Name = "liberdade-accept-shinjuku-peer01" }
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shinjuku_vpc_prop01" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shinjuku_attach_tokyo_vpc01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shinjuku_tgw_rt01.id
  provider = aws.tokyo
}