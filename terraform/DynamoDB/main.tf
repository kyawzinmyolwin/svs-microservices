terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "svs-microservices" # This matches the name you used in 'aws configure'
}


resource "aws_dynamodb_table" "terraform_lock" {
  name         = "svs-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  # Attribute definitions must match your CLI command
  attribute {
    name = "LockID"
    type = "S" # S stands for String
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Project     = "SVS"
    Environment = "Lab"
  }
}