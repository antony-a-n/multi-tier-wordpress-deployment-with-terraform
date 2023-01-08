module "vpc" {
  source             = "/var/vpc-module"
  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = true
}
resource "aws_key_pair" "ssh-key" {
  key_name   = "${var.project}-${var.environment}"
  public_key = file("mykey.pub")
  tags = {
    "Name" = "${var.project}-${var.environment}"
  }
}
resource "aws_ec2_managed_prefix_list" "my-ips" {
  name           = "${var.project}-${var.environment}-prefix-list"
  address_family = "IPv4"
  max_entries    = length(var.iplist)

  dynamic "entry" {
    
    for_each = toset(var.iplist)
    iterator = ip
    
    content {
      cidr = ip.value
    } 
  }
}
resource "aws_security_group" "bastion" {
  name   = "${var.project}-${var.environment}-bastion-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    prefix_list_ids = [aws_ec2_managed_prefix_list.my-ips.id]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project}-${var.environment}-bastion"

  }
}


resource "aws_security_group" "front-end" {
  name   = "${var.project}-${var.environment}-front-end-sg"
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = toset(var.ports-front)
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = var.ssh-outside == true ? ["0.0.0.0/0"] : null
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    "Name" = "${var.project}-${var.environment}-front-end-sg"

  }
}
resource "aws_security_group" "back-end" {
  name   = "${var.project}-${var.environment}-back-end-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port       = var.db-port
    to_port         = var.db-port
    protocol        = "tcp"
    security_groups = [aws_security_group.front-end.id]
  }

  ingress {
    from_port       = var.bastion-port
    to_port         = var.bastion-port
    protocol        = "tcp"
    cidr_blocks     = var.ssh-backend-pub == true ? ["0.0.0.0/0"] : null
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    "Name" = "${var.project}-${var.environment}-back-end-sg"
  }
}

resource "aws_instance" "bastion" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh-key.key_name
  subnet_id              = module.vpc.public_subnets.1
  vpc_security_group_ids = [aws_security_group.bastion.id]
  tags = {
    "Name" = "${var.project}-${var.environment}-bastion-sg"

  }
}
resource "aws_instance" "front-end-server" {

  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.ssh-key.key_name
  subnet_id              = module.vpc.public_subnets.0
  user_data              = data.template_file.web.rendered
  vpc_security_group_ids = [aws_security_group.front-end.id]
  tags = {
    "Name" = "${var.project}-${var.environment}-front-end"
  }
}

resource "aws_instance" "back-end-server" {

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh-key.key_name
  depends_on             = [module.vpc.nat_gateway]
  subnet_id              = module.vpc.private_subnets.0
  user_data              = data.template_file.db.rendered
  vpc_security_group_ids = [aws_security_group.back-end.id]
  tags = {
    "Name" = "${var.project}-${var.environment}-back-end"
  }
}
resource "aws_route53_zone" "private" {
  name = var.private-domain

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.${var.private-domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.back-end-server.private_ip]
}

resource "aws_route53_record" "www-url" {
  zone_id = data.aws_route53_zone.mydomain.zone_id
  name    = "wordpress.${var.domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.front-end-server.public_ip]
}

