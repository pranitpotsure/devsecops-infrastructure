# IAM trust policy: allow the EKS service to assume its cluster role.
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# IAM role used by the EKS control plane.
resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
  tags               = var.tags
}

# Required AWS permissions for the EKS control plane.
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Trust policy: allow EC2 worker nodes to assume their IAM role.
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM role used by the EKS managed worker nodes.
resource "aws_iam_role" "nodes" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
  tags               = var.tags
}

# Allow worker nodes to join and communicate with the cluster.
resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Allow nodes to configure Kubernetes pod networking.
resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Allow worker nodes to pull application images from ECR.
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create the managed Kubernetes control plane.
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    # Place the cluster network interfaces in private subnets.
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true

    # Public API access is restricted to the CIDRs configured above.
    endpoint_public_access = true
    public_access_cidrs    = var.cluster_endpoint_public_access_cidrs
  }

  # Ensure the cluster role has its required policy before creation.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = var.tags
}

# Managed worker nodes run the Bagisto and Next.js containers.
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = aws_iam_role.nodes.arn

  # Worker nodes run in private subnets, not directly on public IPs.
  subnet_ids     = var.private_subnet_ids
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  # Apply worker-node updates in controlled batches.
  update_config {
    max_unavailable = 1
  }

  # Attach required IAM permissions before creating the node group.
  depends_on = [
    aws_iam_role_policy_attachment.worker_node,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr_readonly
  ]

  tags = var.tags
}
