# =============================================================================
# ECR REPOSITORIES
# One repository per microservice — replaces your local registry at
# 192.168.56.90:5000
#
# for_each iterates over the services list, creating one repo per service.
# This means adding a new service in variables.tf automatically creates
# its ECR repo on the next terraform apply — no extra resource blocks needed.
# =============================================================================

resource "aws_ecr_repository" "services" {
  for_each = toset(var.services)

  name                 = each.value
  repository_type      = "PUBLIC"
  image_tag_mutability = "MUTABLE" # allows re-pushing :latest tag

  # Allows terraform destroy to delete the repo even when it contains images.
  # Safe for a home lab — in production you would set this to false to prevent
  # accidental image loss.
  force_delete = true

  # Scan each image for known CVEs on push — free, and good to show
  # in a security-focused portfolio
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt images at rest using AWS-managed KMS key
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = each.value
    Environment = var.environment
  }
}


# =============================================================================
# LIFECYCLE POLICIES
# Automatically deletes old images to control storage costs.
# Keeps only the last N images per repo — older ones are pruned.
#
# Without this, every CI build push accumulates indefinitely.
# At $0.10/GB/month this matters once you have hundreds of builds.
# =============================================================================

resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_retention_count} images"
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


# =============================================================================
# ECR REPOSITORY POLICY
# Allows public access to pull images and EKS node IAM role to pull images.
# Public repositories can be pulled without AWS credentials.
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublicPull"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowEKSPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}
