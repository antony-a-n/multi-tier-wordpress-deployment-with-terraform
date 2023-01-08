output "url" {

  value = "http://${aws_route53_record.www-url.name}"
}

output "dns" {
  value = aws_instance.front-end-server.public_dns
}

output "public_ip" {
  value = aws_instance.front-end-server.public_ip
}


output "db-host" {
  value = local.db-host
}
output "vpc-module-return" {
  value = module.vpc
}
