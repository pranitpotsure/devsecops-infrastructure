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

# IDs of the interface endpoints used for private ECR access.
output "ecr_api_endpoint_id" {
  description = "ECR API VPC endpoint ID."
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "ECR Docker VPC endpoint ID."
  value       = aws_vpc_endpoint.ecr_dkr.id
}

# ID of the S3 gateway endpoint.
output "s3_endpoint_id" {
  description = "S3 gateway VPC endpoint ID."
  value       = aws_vpc_endpoint.s3.id
}

# STS endpoint ID for troubleshooting private IAM requests.
output "sts_endpoint_id" {
  description = "STS interface endpoint ID."
  value       = aws_vpc_endpoint.sts.id
}

# Secrets Manager endpoint ID.
output "secrets_manager_endpoint_id" {
  description = "Secrets Manager interface endpoint ID."
  value       = aws_vpc_endpoint.secrets_manager.id
}

# CloudWatch Logs endpoint ID.
output "logs_endpoint_id" {
  description = "CloudWatch Logs interface endpoint ID."
  value       = aws_vpc_endpoint.logs.id
}
