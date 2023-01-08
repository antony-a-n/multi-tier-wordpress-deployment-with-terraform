variable "project" {
  default = "demo"
}

variable "environment" {
  default = "test"
}

variable "vpc_cidr" {
  default = "172.16.0.0"
}
  

locals {
  az = length(data.aws_availability_zones.available.names)
}

variable "enable_nat_gateway" {
  type = bool
  default = true
}

variable "region" {
  default     = "ap-south-1"
  description = "default region"
}
 
locals {
  common_tags = {
    "project"     = var.project
    "environment" = var.environment
  }
}
