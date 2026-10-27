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
