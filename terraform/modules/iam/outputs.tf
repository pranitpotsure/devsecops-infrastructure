# Role ARN to associate with the Kubernetes service account.
output "workload_role_arn" {
  description = "IAM role ARN for the Bagisto Kubernetes workload."
  value       = aws_iam_role.bagisto_workload.arn
}

# OIDC provider ARN registered for this EKS cluster.
output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for EKS."
  value       = aws_iam_openid_connect_provider.eks.arn
}
