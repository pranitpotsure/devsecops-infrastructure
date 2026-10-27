# Name of the RDS database instance.
variable "identifier" {
  description = "Unique identifier for the RDS instance."
  type        = string
}

# Database engine version must be supported by AWS in the chosen region.
variable "engine_version" {
  description = "MySQL engine version for RDS."
  type        = string
}

# Network location for the database.
variable "private_subnet_ids" {
  description = "Private subnet IDs used by the RDS subnet group."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the database will be deployed."
  type        = string
}

# Security group IDs allowed to connect to MySQL.
variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to MySQL on port 3306."
  type        = list(string)
  default     = []
}

# Database capacity and storage configuration.
variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial database storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GiB."
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Initial MySQL database name."
  type        = string
  default     = "bagisto"
}

variable "master_username" {
  description = "Master username for the database."
  type        = string
  default     = "bagistoadmin"
}

# Keep the database private and encrypted.
variable "multi_az" {
  description = "Whether to deploy a standby database in another Availability Zone."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the database."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the database."
  type        = bool
  default     = false
}

# Common resource tags.
variable "tags" {
  description = "Tags applied to RDS resources."
  type        = map(string)
  default     = {}
}
