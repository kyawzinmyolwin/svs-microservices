terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  # S3 backend for remote state — create the bucket and DynamoDB table
  # manually before running terraform init (see README)
  backend "s3" {
    bucket         = "svs-tfstate"
    key            = "svs-microservices/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "svs-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "svs-microservices"

  default_tags {
    tags = {
      Project     = "svs-microservices"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
