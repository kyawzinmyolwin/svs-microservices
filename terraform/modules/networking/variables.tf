variable "cluster_name" {
  description = "EKS cluster name — used in subnet tags so EKS can discover subnets"
  type        = string
}

variable "environment" {
  description = "Environment label used in resource names and tags"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs to create subnets in — must match length of subnet CIDR lists"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}
