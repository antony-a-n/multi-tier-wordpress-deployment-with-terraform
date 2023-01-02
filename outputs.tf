output "URL"{

    value = "http://${aws_route53_record.www-url.name}"
} 

output "public-dns-name"{
    value = aws_instance.front-end-server.public_dns 
}
