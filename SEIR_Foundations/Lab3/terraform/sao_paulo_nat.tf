############################################
# Locals
############################################
locals {
  ports_http     = 80
  ports_ssh      = 22
  ports_https    = 443
  ports_dns      = 53
  db_port        = 3306
  tcp_protocol   = "tcp"
  udp_protocol   = "udp"
  all_ip_address = "0.0.0.0/0"
  all_ports      = "-1"
  all_protocol   = "All"
  http           = "http"
  https          = "https"
}

############################################
# VPC + Internet Gateway
############################################

resource "aws_vpc" "sao_paulo_sao_paulo_satellite_vpc" {
  cidr_block           = var.liberdade_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.liberdade}-vpc01"
  }
}

# Explanation: Even Wookiees need to reach the wider galaxy—IGW is your door to the public internet.
resource "aws_internet_gateway" "sao_paulo_satellite_igw01" {
  vpc_id = aws_vpc.sao_paulo_sao_paulo_satellite_vpc.id

  tags = {
    Name = "${vars.liberdade}-igw01"
  }
}

############################################
# NAT Gateway + EIP
############################################

resource "aws_eip" "sao_paulo_satellite_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${vars.liberdade}-nat-eip01"
  }
}

resource "aws_nat_gateway" "sao_paulo_satellite_nat01" {
  allocation_id = aws_eip.sao_paulo_satellite_nat_eip01.id
  subnet_id     = aws_subnet.liberdade_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${vars.liberdade}-nat01"
  }

  depends_on = [aws_internet_gateway.sao_paulo_satellite_igw01]
}