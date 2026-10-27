# Call the reusable networking module.
module "networking" {
  source = "./modules/networking"

  # Project/environment prefix for resource names.
  name = "${var.project_name}-${var.environment}"

  # Network configuration comes from the root variables.
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # NAT is disabled by default to avoid accidental costs.
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # Apply the root tags to network resources.
  tags = var.common_tags
}



# Create private ECR repositories for the Bagisto backend and Next.js storefront.
module "ecr" {
  source = "./modules/ecr"

  # Use the project name and environment in repository names.
  project_name = var.project_name
  environment  = var.environment

  # Store the two application container images separately.
  repositories = [
    "bagisto-backend",
    "nextjs-storefront"
  ]

  # Apply the common project tags.
  tags = var.common_tags
}


# Create the managed Kubernetes cluster and its worker nodes.
module "eks" {
  source = "./modules/eks"

  # Identify the cluster using the project and environment names.
  cluster_name       = "${var.project_name}-${var.environment}"
  kubernetes_version = var.kubernetes_version

  # Place the EKS control plane networking and worker nodes in private subnets.
  private_subnet_ids = module.networking.private_subnet_ids

  # Restrict public Kubernetes API access to explicitly trusted IP ranges.
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Configure worker node types and autoscaling capacity.
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size

  # Apply shared project tags.
  tags = var.common_tags
}

# Create the private MySQL database for Bagisto.
module "rds" {
  source = "./modules/rds"

  # Use a consistent database identifier.
  identifier     = "${var.project_name}-${var.environment}-mysql"
  engine_version = var.mysql_engine_version
  instance_class = var.rds_instance_class

  # Keep the database inside the VPC private subnets.
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  # Permit MySQL connections only from the EKS cluster security group.
  allowed_security_group_ids = [
    module.eks.cluster_security_group_id
  ]

  # Database configuration.
  database_name   = "bagisto"
  master_username = "bagistoadmin"
  multi_az        = var.rds_multi_az

  # Enable protection against accidental database deletion.
  deletion_protection = true
  skip_final_snapshot = false

  # Apply the shared project tags.
  tags = var.common_tags
}

# Store Bagisto product images and media in a private S3 bucket.
module "s3" {
  source = "./modules/s3"

  # S3 bucket names must be globally unique across AWS accounts.
  # The final name may need an account-specific suffix before deployment.
  bucket_name = "${var.project_name}-${var.environment}-media"

  # Apply common project tags.
  tags = var.common_tags
}

# Give the Bagisto Kubernetes service account restricted S3 permissions.
module "iam" {
  source = "./modules/iam"

  # Trust the identity provider belonging to our EKS cluster.
  oidc_issuer_url = module.eks.oidc_issuer_url

  # Restrict this role to the Bagisto namespace and service account.
  kubernetes_namespace = "bagisto"
  service_account_name = "bagisto-service-account"

  # Grant access only to our private media bucket.
  media_bucket_arn = module.s3.bucket_arn

  tags = var.common_tags
}
