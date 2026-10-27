# Name of the Kubernetes namespace where the application runs.
variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the Bagisto application."
  type        = string
  default     = "bagisto"
}

# Kubernetes service account trusted by the IAM role.
variable "service_account_name" {
  description = "Service account used by the Bagisto workload."
  type        = string
  default     = "bagisto-service-account"
}

# OIDC issuer URL exposed by the EKS cluster.
variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster."
  type        = string
}

# S3 bucket to which the application needs access.
variable "media_bucket_arn" {
  description = "ARN of the private Bagisto media bucket."
  type        = string
}

# Common resource tags.
variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
