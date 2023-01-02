#setting up key-pair

resource "aws_key_pair" "ssh-key" {
  key_name   = "${var.project}-${var.environment}"
  public_key = file("mykey.pub")
  tags = {
    "Name"        = "${var.project}-${var.environment}"
  }
}

#creating VPC

resource "aws_vpc" "vpc-terra" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

resource "aws_internet_gateway" "terra-gw" {
  vpc_id = aws_vpc.vpc-terra.id

  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

#creating public subnets

resource "aws_subnet" "public" {

  count = local.az
  vpc_id     = aws_vpc.vpc-terra.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true 
  tags = {
    Name = "${var.project}-${var.environment}-public"
  }
}

#creating private subnets

resource "aws_subnet" "private" {

  count = local.az
  vpc_id     = aws_vpc.vpc-terra.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, "${count.index + local.az}")
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false 
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}

resource "aws_eip" "vpc-terra-eip" {
  vpc      = true
}

#setting up natgateway

resource "aws_nat_gateway" "terra-nat" {
  allocation_id = aws_eip.vpc-terra-eip.id
  subnet_id     = aws_subnet.public.1.id
  

  tags = {
    Name = "${var.project}-${var.environment}-NAT"
  }

}
#setting up public route table 

resource "aws_route_table" "vpc-terra-public" {
  vpc_id = aws_vpc.vpc-terra.id

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
  vpc_id = aws_vpc.vpc-terra.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id =aws_nat_gateway.terra-nat.id
}
    tags = {
    Name = "${var.project}-${var.environment}-rtb-private"
  
}
}

#setting up public route table association

resource "aws_route_table_association" "public" {
  count = local.az
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.vpc-terra-public.id
}



#setting up private  route table association

resource "aws_route_table_association" "private" {
  count = local.az
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.vpc-terra-private.id
}

#creating security groups

resource "aws_security_group" "bastion" {
  name        = "${var.project}-${var.environment}-bastion"
  vpc_id = aws_vpc.vpc-terra.id
ingress {
    description      = "allow ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

 egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


resource "aws_security_group" "front-end" {
  name        = "${var.project}-${var.environment}-front-end"
  vpc_id = aws_vpc.vpc-terra.id

    ingress {
    description      = "allow ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups =  [aws_security_group.bastion.id]
    ipv6_cidr_blocks = ["::/0"]
  }

     ingress {
    description      = "allow http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "allow http access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

 egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


resource "aws_security_group" "back-end" {
  name        = "${var.project}-${var.environment}-back-end"
  vpc_id = aws_vpc.vpc-terra.id

    ingress {
    description      = "allow ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups = [aws_security_group.bastion.id]
    ipv6_cidr_blocks = ["::/0"]
  }

     ingress {
    description      = "allow mysql access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.front-end.id]

    ipv6_cidr_blocks = ["::/0"]
  }

   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

#creating instances

resource "aws_instance" "front-end-server" {
  ami                    = var.instance_ami
  user_data              = file("frontend.sh")
  instance_type          = var.instance_type
  depends_on = [aws_instance.back-end-server]
  subnet_id =aws_subnet.public.0.id
  key_name               = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.front-end.id]
  tags = {
    "Name"        = "${var.project}-${var.environment}-front-end"
    
  }
}

resource "aws_instance" "back-end-server" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.0.id
  depends_on = [aws_nat_gateway.terra-nat]
  key_name               = aws_key_pair.ssh-key.key_name
  user_data              = file("mysql.sh")
  vpc_security_group_ids = [aws_security_group.back-end.id]
  tags = {
    "Name"        = "${var.project}-${var.environment}-backend"
    
  }
}

resource "aws_instance" "bastion-server" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.1.id
  key_name               = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  tags = {
    "Name"        = "${var.project}-${var.environment}-bastion"
    
  }
}

#creating route 53 zone

resource "aws_route53_zone" "private" {
  name = var.private-domain

  vpc {
    vpc_id = aws_vpc.vpc-terra.id
  }
}
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.${var.private-domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.back-end-server.private_ip]
}

#fetching data of existing route 53 zone
resource "aws_route53_record" "www-url" {
  zone_id = data.aws_route53_zone.mydomain.zone_id
  name    = "wordpress.${var.domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.front-end-server.public_ip]
}
