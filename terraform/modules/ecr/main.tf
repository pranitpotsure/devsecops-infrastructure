# Create one private ECR repository for each application image.
resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name = "${var.project_name}-${var.environment}-${each.value}"

  # Immutable tags prevent an existing image tag from being overwritten.
  image_tag_mutability = "IMMUTABLE"

  # Protect repositories from accidental deletion when they contain images.
  force_delete = false

  # Scan newly pushed images for known vulnerabilities.
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt images at rest using AWS-managed encryption.
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name      = "${var.project_name}-${var.environment}-${each.value}"
    Component = "container-registry"
  })
}

# Remove untagged images older than 14 days to control storage growth.
resource "aws_ecr_lifecycle_policy" "untagged" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire untagged images after 14 days"

      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 14
      }

      action = {
        type = "expire"
      }
    }]
  })
}
