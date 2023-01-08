variable "project" {
  default = "wordpress"
}

variable "environment" {
  default = "staging"
}

variable "region" {
  default     = "ap-south-1"
  description = "default region"
}

variable "access_key" {
  default     = "***************"
  description = "accesskey"
}

variable "secret_key" {
  default     = "*****************"
  description = "secretkey"
}

variable "instance_ami" {
  default = "ami-074dc0a6f6c764218"
}

variable "instance_type" {
  default = "t2.micro"
}
locals {
  common_tags = {
    "project"     = var.project
    "environment" = var.environment
  }
}
variable "vpc_cidr" {
  default = "172.16.0.0/16"
}
locals {
  az = length(data.aws_availability_zones.available.names)
}
variable "private-domain" {
  default = "antonyan.local"
}

variable "domain" {
  default = "antonyan.tech"
}

variable "database" {
  default = "wp_db"
}
variable "database-user" {
  default = "dbuser"
}

variable "database-password" {
  default = "wp123"
}

variable "root-password" {
  default = "qwertyuiop@123"
}

locals {
  db-host = "db.${var.private-domain}"
}

variable "iplist" {
  type    = list(string)
  default = ["137.59.78.57/32", "1.2.3.4/32", "2.2.2.2/32", "49.15.201.201/32", "0.0.0.0/0"]
}

variable "ports-front" {
  type    = list(string)
  default = ["443", "80", "8080"]
}

variable "ssh-outside" {
  default = false
}

variable "ssh-backend-pub" {
  default = false
}

variable "db-port" {
  default = 3306
}

variable "bastion-port" {
  default = 22
}
