resource "aws_route_table" "route_table_public" {
  vpc_id = var.vpc_route
  tags = {
    Name = var.route_name_public 
  }
}
resource "aws_route_table" "route_table_private" {
  vpc_id = var.vpc_route
  tags = {
    Name = var.route_name_private
  }
}
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = var.vpc_igw

  tags = {
    Name = "vpc_igw"
  }
}

# Elastic-IP (eip) for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  
}
# NAT_gateway
resource "aws_nat_gateway" "nat_gatway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = var.subnet_id_nat
  depends_on = [
    aws_eip.nat_eip
  ]
  tags = {
    Name        = "natgatway"
    
  }
}
resource "aws_route" "public_route" {
  route_table_id         = var.routepublic
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.internet_gateway.id
}
resource "aws_route" "private_route" {
  route_table_id         = var.routeprivate
  destination_cidr_block = var.destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.nat_gatway.id
}
resource "aws_route_table_association" "public" {
  for_each = var.aws_subnet_public
  subnet_id      = each.value
  route_table_id = var.routepublic
}

resource "aws_route_table_association" "private" {
  for_each = var.aws_subnet_private
  subnet_id      = each.value
  route_table_id = var.routeprivate
}
