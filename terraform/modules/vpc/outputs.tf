# VPC Module Outputs
# Exposes VPC resources for use by other modules

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ips" {
  description = "List of Elastic IP addresses of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Backward compatibility - single subnet outputs
output "public_subnet_id" {
  description = "The ID of the first public subnet (for backward compatibility)"
  value       = aws_subnet.public[0].id
}

output "private_subnet_id" {
  description = "The ID of the first private subnet (for backward compatibility)"
  value       = aws_subnet.private[0].id
}

output "nat_gateway_ip" {
  description = "The Elastic IP of the first NAT Gateway (for backward compatibility)"
  value       = aws_eip.nat[0].public_ip
}
