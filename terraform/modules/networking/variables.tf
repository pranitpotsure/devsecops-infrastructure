# Prefix used to name the network resources.
variable "name" {
  description = "Name prefix for networking resources."
  type        = string
}

# Private address range allocated to the VPC.
variable "vpc_cidr" {
  description = "IPv4 CIDR range for the VPC."
  type        = string
}

# Availability Zones where the public and private subnets will be created.
variable "availability_zones" {
  description = "Availability Zones for the subnets."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }
}

# Public subnet address ranges, one per Availability Zone.
variable "public_subnet_cidrs" {
  description = "CIDR ranges for public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two public subnet CIDRs are required."
  }
}

# Private subnet address ranges, one per Availability Zone.
variable "private_subnet_cidrs" {
  description = "CIDR ranges for private subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnet CIDRs are required."
  }
}

# Controls whether NAT Gateway resources are created.
variable "enable_nat_gateway" {
  description = "Enable billable NAT Gateway resources."
  type        = bool
  default     = false
}

# Controls whether private subnets share one NAT Gateway.
variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway when enabled."
  type        = bool
  default     = true
}

# Additional tags to apply to supported network resources.
variable "tags" {
  description = "Tags applied to networking resources."
  type        = map(string)
  default     = {}
}
