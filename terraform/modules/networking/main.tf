# VPC: the isolated network that will contain our AWS infrastructure.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# Internet Gateway: provides internet routing for public subnets.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public subnets: intended for internet-facing load balancers.
# Each subnet is assigned to a different Availability Zone.
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                     = "${var.name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })

  lifecycle {
    precondition {
      condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
      error_message = "Provide one public subnet CIDR for each Availability Zone."
    }
  }
}

# Private subnets: intended for EKS worker nodes and private application services.
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name                              = "${var.name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })

  lifecycle {
    precondition {
      condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
      error_message = "Provide one private subnet CIDR for each Availability Zone."
    }
  }
}

# Public route table: sends internet-bound traffic through the Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Associate every public subnet with the public route table.
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Elastic IPs are created only when NAT is enabled.
# NAT Gateway and its Elastic IP may incur AWS charges.
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : length(aws_subnet.public)
  ) : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateway lets private resources initiate outbound internet connections.
# One shared NAT is cheaper; one per public subnet is more resilient.
resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : length(aws_subnet.public)
  ) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.this]

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${count.index + 1}"
  })
}

# Create an independent route table for each private subnet.
resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt-${count.index + 1}"
  })
}

# Add a default outbound route only if NAT is enabled.
resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? length(aws_subnet.private) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  # Share NAT index 0 when single_nat_gateway is true.
  # Otherwise, each private subnet uses its matching NAT index.
  nat_gateway_id = aws_nat_gateway.this[
    var.single_nat_gateway ? 0 : count.index
  ].id
}

# Associate each private subnet with its own private route table.
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Read the AWS region selected by the root provider.
data "aws_region" "current" {}

# Allow private resources to connect to AWS interface endpoints over HTTPS.
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name}-vpc-endpoints"
  description = "HTTPS access to private AWS service endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from within the project VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow endpoint response and service traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpc-endpoints"
  })
}

# ECR API endpoint: lets private workloads call the ECR API.
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-ecr-api-endpoint"
  })
}

# ECR Docker endpoint: lets private workloads authenticate and pull images.
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-ecr-dkr-endpoint"
  })
}

# S3 gateway endpoint: provides private access to S3, including ECR image layers.
# Gateway endpoints have no additional hourly endpoint charge.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # Add the endpoint route to each private subnet's route table.
  route_table_ids = aws_route_table.private[*].id

  tags = merge(var.tags, {
    Name = "${var.name}-s3-endpoint"
  })
}

# STS endpoint: supports private AWS Security Token Service requests.
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-sts-endpoint"
  })
}

# Secrets Manager endpoint: provides private access to stored credentials.
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-secretsmanager-endpoint"
  })
}

# CloudWatch Logs endpoint: allows private delivery to the Logs API.
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-logs-endpoint"
  })
}
