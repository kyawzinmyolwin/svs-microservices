terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
  
  # For public ECR, we need to configure the public ECR region (us-east-1)
  # but our resources are in ap-southeast-1
}

provider "aws" {
  alias  = "public"
  region = "us-east-1"
}
