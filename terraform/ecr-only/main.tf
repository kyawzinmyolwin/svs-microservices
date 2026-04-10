# =============================================================================
# ECR PUBLIC REPOSITORIES
# One public repository per microservice in AWS Public ECR Gallery
# These repositories are accessible to anyone WITHOUT AWS authentication
#
# Note: Public ECR operates in us-east-1 region only
# =============================================================================

resource "aws_ecrpublic_repository" "services" {
  for_each = toset(var.services)

  provider = aws.public

  repository_name = each.value

  # Catalog data for the public registry
  catalog_data {
    about_text        = "Public Docker image for ${each.value} service"
    description       = "Service: ${each.value}"
    operating_systems = ["Linux"]
  }

  tags = {
    Name        = each.value
    Environment = var.environment
  }
}


# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_caller_identity" "current" {}
