# Explanation: Liberdade is São Paulo’s Japanese town—local doctors, local compute, remote data.
resource "aws_ec2_transit_gateway" "liberdade_tgw01" {
  provider                        = aws.sao_paulo
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "liberdade-tgw01 (Sao Paulo spoke)"
  tags                            = { Name = "liberdade-tgw01" }
}

# Explanation: Create an explicit TGW route table so Sao Paulo forwarding is deterministic.
resource "aws_ec2_transit_gateway_route_table" "liberdade_tgw_rt01" {
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw01.id
  provider           = aws.sao_paulo
  tags               = { Name = "liberdade-tgw-rt01" }
}

# Explanation: Read the current Tokyo-created peering attachment so Terraform can react to real AWS state.
data "aws_ec2_transit_gateway_peering_attachment" "liberdade_peer01" {
  count    = var.shinjuku_peer_attachment_id == null ? 0 : 1
  provider = aws.sao_paulo
  id       = var.shinjuku_peer_attachment_id
}

locals {
  liberdade_peer_state      = try(data.aws_ec2_transit_gateway_peering_attachment.liberdade_peer01[0].state, null)
  liberdade_peer_manageable = local.liberdade_peer_state == "pendingAcceptance"
  liberdade_peer_available  = local.liberdade_peer_state == "available"
}

# Explanation: Liberdade attaches to its VPC—compute can now reach Tokyo legally, through the controlled corridor.
resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_attach_sp_vpc01" {
  provider                                        = aws.sao_paulo
  transit_gateway_id                              = aws_ec2_transit_gateway.liberdade_tgw01.id
  vpc_id                                          = aws_vpc.liberdade_vpc01.id
  subnet_ids                                      = aws_subnet.liberdade_private_subnets[*].id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = { Name = "liberdade-attach-sp-vpc01" }
}

# Explanation: Associate the Sao Paulo VPC attachment with the explicit Sao Paulo TGW route table.
resource "aws_ec2_transit_gateway_route_table_association" "liberdade_vpc_assoc01" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.liberdade_attach_sp_vpc01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.liberdade_tgw_rt01.id
  provider                       = aws.sao_paulo
}

# Explanation: Propagate the Liberdade VPC attachment into the explicit Sao Paulo TGW route table.
resource "aws_ec2_transit_gateway_route_table_propagation" "liberdade_vpc_prop01" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.liberdade_attach_sp_vpc01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.liberdade_tgw_rt01.id
  provider                       = aws.sao_paulo
}

# Explanation: Accept the corridor from Shinjuku only when the live peering attachment is actually manageable.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer01" {
  count                         = local.liberdade_peer_manageable ? 1 : 0
  transit_gateway_attachment_id = var.shinjuku_peer_attachment_id
  provider                      = aws.sao_paulo
  tags                          = { Name = "liberdade-accept-peer01" }
}

# Explanation: Associate the live Tokyo-created peering attachment with the explicit Sao Paulo TGW route table only after acceptance.
resource "aws_ec2_transit_gateway_route_table_association" "liberdade_peer_assoc01" {
  count                          = local.liberdade_peer_available ? 1 : 0
  transit_gateway_attachment_id  = var.shinjuku_peer_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.liberdade_tgw_rt01.id
  provider                       = aws.sao_paulo

  depends_on = [aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01]
}

# Explanation: The Sao Paulo TGW route table must know that Shinjuku's CIDR lives behind the live peering attachment.
resource "aws_ec2_transit_gateway_route" "liberdade_tgw_to_shinjuku_route01" {
  count                          = local.liberdade_peer_available ? 1 : 0
  destination_cidr_block         = var.shinjuku_vpc
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.liberdade_tgw_rt01.id
  transit_gateway_attachment_id  = var.shinjuku_peer_attachment_id
  provider                       = aws.sao_paulo

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01,
    aws_ec2_transit_gateway_route_table_association.liberdade_peer_assoc01
  ]
}