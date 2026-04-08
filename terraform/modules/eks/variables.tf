variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment label used in resource names and tags"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the networking module"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes — from networking module"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for load balancers — from networking module"
  type        = list(string)
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes — t3.medium is minimum for Vault + Kong"
  type        = string
  default     = "t3.small"
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
