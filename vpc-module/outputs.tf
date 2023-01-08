output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "nat_gateway"{

  value = aws_nat_gateway.terra-nat[*].id
}

output "public_subnets" { 
    
  value = aws_subnet.public[*].id 
}

output "private_subnets" { 
    
  value = aws_subnet.private[*].id 
}
