# VPC ID used by other infrastructure components.
output "vpc_id" {
  description = "ID of the project VPC."
  value       = aws_vpc.this.id
}

# Public subnet IDs, mainly for internet-facing load balancers.
output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

# Private subnet IDs for EKS worker nodes and RDS.
output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

# Useful when checking or documenting network address allocation.
output "public_subnet_cidrs" {
  description = "CIDR ranges of the public subnets."
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR ranges of the private subnets."
  value       = aws_subnet.private[*].cidr_block
}

# Empty when NAT is disabled.
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways."
  value       = aws_nat_gateway.this[*].id
}
