# EKS cluster name.
variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

# Kubernetes version supported by Amazon EKS.
variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
}

# Private subnets where EKS and worker nodes run.
variable "private_subnet_ids" {
  description = "Private subnet IDs."
  type        = list(string)
}

# Restrict public Kubernetes API access to trusted IP ranges.
variable "cluster_endpoint_public_access_cidrs" {
  description = "Trusted public IP CIDRs, preferably your IP with /32."
  type        = list(string)

  validation {
    condition     = length(var.cluster_endpoint_public_access_cidrs) > 0
    error_message = "Provide at least one trusted CIDR."
  }
}

# EC2 instance types used by the managed worker nodes.
variable "node_instance_types" {
  description = "Worker node instance types."
  type        = list(string)
  default     = ["t3.medium"]
}

# Desired, minimum and maximum worker-node counts.
variable "node_desired_size" {
  type        = number
  description = "Desired worker-node count."
  default     = 2
}

variable "node_min_size" {
  type        = number
  description = "Minimum worker-node count."
  default     = 2
}

variable "node_max_size" {
  type        = number
  description = "Maximum worker-node count."
  default     = 4
}

# Common tags for EKS resources.
variable "tags" {
  description = "Tags applied to EKS resources."
  type        = map(string)
  default     = {}
}
