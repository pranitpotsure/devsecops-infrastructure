# AWS region. ap-south-1 is the Mumbai region.
variable "aws_region" {
  description = "AWS region for the infrastructure."
  type        = string
  default     = "ap-south-1"
}

# Project identifier used in resource names.
variable "project_name" {
  description = "Name of the project."
  type        = string
  default     = "bagisto"
}

# Environment name, such as development, staging, or production.
variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "production"
}

# CIDR range for the VPC.
variable "vpc_cidr" {
  description = "IPv4 network range for the project VPC."
  type        = string
  default     = "10.40.0.0/16"
}

# Availability Zones used for high availability.
variable "availability_zones" {
  description = "Availability Zones for the network."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "Provide at least two unique Availability Zones."
  }
}

# Public subnets can host internet-facing load balancers.
variable "public_subnet_cidrs" {
  description = "CIDR ranges for public subnets."
  type        = list(string)
  default     = ["10.40.0.0/24", "10.40.1.0/24", "10.40.2.0/24"]
}

# Private subnets are intended for EKS worker nodes and RDS.
variable "private_subnet_cidrs" {
  description = "CIDR ranges for private subnets."
  type        = list(string)
  default     = ["10.40.10.0/24", "10.40.11.0/24", "10.40.12.0/24"]
}

# NAT Gateway enables outbound internet access from private subnets.
# It is disabled by default to avoid accidental AWS charges.
variable "enable_nat_gateway" {
  description = "Whether to create billable NAT Gateway resources."
  type        = bool
  default     = false
}

# One NAT Gateway costs less, while one per AZ provides better resilience.
variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway when NAT is enabled."
  type        = bool
  default     = true
}

# Common tags applied to supported AWS resources.
variable "common_tags" {
  description = "Additional tags for project resources."
  type        = map(string)
  default = {
    Application = "Bagisto"
    Owner       = "DevSecOps"
  }
}

# Kubernetes version to use when creating the EKS cluster.
variable "kubernetes_version" {
  description = "Kubernetes version supported by EKS in the selected AWS region."
  type        = string
  default     = "1.34"
}

# Trusted public IP ranges allowed to access the EKS Kubernetes API.
# Supply your real public IP with /32 in terraform.tfvars before deployment.
variable "cluster_endpoint_public_access_cidrs" {
  description = "Trusted public CIDR ranges allowed to access the EKS API."
  type        = list(string)
}

# EC2 instance types used by the EKS managed worker node group.
variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

# Desired, minimum, and maximum worker node counts.
variable "node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 4
}

# MySQL version supported by RDS in the selected AWS region.
# Confirm the exact supported version before deployment.
variable "mysql_engine_version" {
  description = "Supported MySQL engine version for RDS."
  type        = string
}

# RDS capacity and availability settings.
variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_multi_az" {
  description = "Whether RDS should use Multi-AZ deployment."
  type        = bool
  default     = false
}
