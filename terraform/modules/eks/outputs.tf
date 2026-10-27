# Cluster name used by deployment scripts and kubeconfig commands.
output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

# Kubernetes API endpoint.
output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

# Worker-node IAM role ARN for reference and troubleshooting.
output "node_role_arn" {
  description = "IAM role ARN for worker nodes."
  value       = aws_iam_role.nodes.arn
}

# Expose the EKS cluster security group so approved workloads can reach RDS.
output "cluster_security_group_id" {
  description = "Security group ID associated with the EKS cluster."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

# Expose the issuer URL required for IAM Roles for Service Accounts.
output "oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
