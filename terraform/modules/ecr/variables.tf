# Project name used as a prefix for repository names.
variable "project_name" {
  description = "Name of the project."
  type        = string
}

# Environment separates production repositories from other environments.
variable "environment" {
  description = "Deployment environment."
  type        = string
}

# Names of the container repositories to create.
variable "repositories" {
  description = "Docker image repositories for the applications."
  type        = list(string)
  default     = ["bagisto-backend", "nextjs-storefront"]
}

# Common resource tags.
variable "tags" {
  description = "Tags applied to ECR resources."
  type        = map(string)
  default     = {}
}
