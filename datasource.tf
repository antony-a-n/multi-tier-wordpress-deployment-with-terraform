data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "mydomain" {
  name         = var.domain
  private_zone = false
}
