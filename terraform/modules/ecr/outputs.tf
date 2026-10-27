# Repository URLs used by the CI/CD pipeline to push and pull images.
output "repository_urls" {
  description = "Map of ECR repository names to repository URLs."
  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.repository_url
  }
}

# Repository ARNs can be used in IAM policies.
output "repository_arns" {
  description = "Map of ECR repository names to ARNs."
  value = {
    for name, repository in aws_ecr_repository.this :
    name => repository.arn
  }
}
