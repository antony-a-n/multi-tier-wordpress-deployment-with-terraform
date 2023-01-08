data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "mydomain" {
  name         = var.domain
  private_zone = false
}

data "template_file" "db" {
  template = "${file("${path.module}/mysql.sh")}"
  vars = {
    db_name = var.database
    db_user = var.database-user
    db_password = var.database-password
    db_root_password = var.root-password
  }
}

data "template_file" "web"{
  template = "${file("${path.module}/frontend.sh")}"
  vars = {
    domain = local.db-host
    db_name = var.database
    db_user = var.database-user
    db_password = var.database-password
    db_root_password = var.root-password
  }
}
