# Configure the AWS provider used by the root Terraform configuration.
provider "aws" {
  # AWS region where the infrastructure will eventually be deployed.
  region = var.aws_region

  # Apply these tags automatically to supported AWS resources.
  default_tags {
    tags = {
      Project     = "DevSecOps-Bagisto"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
