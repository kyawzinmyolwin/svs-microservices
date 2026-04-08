variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1" # Singapore
}

variable "environment" {
  description = "Environment name used for tagging"
  type        = string
  default     = "homelab"
}

variable "cluster_name" {
  description = "EKS cluster name — also used for subnet tags required by EKS"
  type        = string
  default     = "svs-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ap-southeast-1 has three AZs: a, b, c
variable "availability_zones" {
  description = "AZs to spread subnets across — use all three for EKS HA"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets — one per AZ (EKS nodes and RDS go here)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "image_retention_count" {
  description = "Number of images to retain per ECR repository"
  type        = number
  default     = 5
}

variable "master_username" {
  description = "RDS master username"
  type        = string
  default     = "svs_admin"
  sensitive   = true
}

variable "master_password" {
  description = "RDS master password — set via TF_VAR_master_password env var, never hardcode"
  type        = string
  sensitive   = true
}
