# ECR Module - Main Configuration
# Creates ECR repositories with image scanning and lifecycle policies
# Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6

# Create ECR repositories for each service
resource "aws_ecr_repository" "repositories" {
  for_each = toset(var.repository_names)

  name                 = "${var.project_name}-${each.value}"
  image_tag_mutability = "MUTABLE"

  # Requirement 2.4: Configure image scanning on push for all ECR repositories
  image_scanning_configuration {
    scan_on_push = true
  }

  # Enable encryption with AWS managed key
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${each.value}"
    }
  )
}

# Requirement 2.5: Configure lifecycle policies to retain the last 10 images per repository
resource "aws_ecr_lifecycle_policy" "lifecycle_policies" {
  for_each = aws_ecr_repository.repositories

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain last ${var.image_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
