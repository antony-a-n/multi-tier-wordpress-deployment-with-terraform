resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}
 
resource "aws_internet_gateway" "terra-gw" {
  vpc_id = aws_vpc.vpc.id
 
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}
 
resource "aws_subnet" "public" {
 
  count                   = local.az
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.environment}-public"
  }
}
 
resource "aws_subnet" "private" {
 
  count                   = local.az
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, "${count.index + local.az}")
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}
 
resource "aws_eip" "vpc-terra-eip" {
  count = var.enable_nat_gateway ? 1 : 0
  vpc = true
}
 
#setting up natgateway
 
resource "aws_nat_gateway" "terra-nat" {
  count = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.vpc-terra-eip.0.id
  subnet_id     = aws_subnet.public[1].id
  depends_on = [ aws_internet_gateway.terra-gw ]
 
  tags = {
    Name = "${var.project}-${var.environment}-NAT"
  }
 
}
#setting up public route table
 
resource "aws_route_table" "vpc-terra-public" {
  vpc_id = aws_vpc.vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra-gw.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-rtb-public"
 
  }
}
 
#setting up private route-table
 
resource "aws_route_table" "vpc-terra-private" {
  vpc_id = aws_vpc.vpc.id
 
  #route {
    #cidr_block     = "0.0.0.0/0"
    #nat_gateway_id = aws_nat_gateway.terra-nat.id
  #}
  tags = {
    Name = "${var.project}-${var.environment}-rtb-private"
 
  }
}

resource "aws_route" "nat-status" {
  count = var.enable_nat_gateway ? 1 : 0
  route_table_id  = aws_route_table.vpc-terra-private.id
  nat_gateway_id  = aws_nat_gateway.terra-nat.0.id
  destination_cidr_block    = "0.0.0.0/0"
  depends_on                = [ aws_internet_gateway.terra-gw ]
}
 
#setting up public route table association
 
resource "aws_route_table_association" "public" {
  count          = local.az
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.vpc-terra-public.id
}
 
 
 
#setting up private  route table association
 
resource "aws_route_table_association" "private" {
  count          = local.az
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.vpc-terra-private.id
}
