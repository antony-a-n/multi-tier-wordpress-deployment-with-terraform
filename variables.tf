variable "project" {
  default     = "test" 
}

variable "environment" {
  default     = "production"
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
 "project" = var.project
 "environment" = var.environment 
}
}
variable "vpc_cidr" {
    default = "172.16.0.0/16"
}


locals {
   az = length (data.aws_availability_zones.available.names)
}
variable "port" {
  type = list(string)
  default = ["22","3306","80","443"]
}

variable "private-domain"{
   default= "antonyan.local"
}

variable "domain"{
  default = "antonyan.tech"

}
