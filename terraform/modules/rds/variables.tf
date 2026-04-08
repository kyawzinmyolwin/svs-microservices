variable "environment" {
  description = "Environment label used in resource names and tags"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the networking module"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS — from networking module"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR block — used to allow MySQL access from within the VPC only"
  type        = string
}

variable "instance_class" {
  description = "RDS instance type — db.t3.micro is Free Tier eligible for 12 months"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GB — 20GB is Free Tier limit"
  type        = number
  default     = 20
}

# Databases — one per service, matching your existing schema names
variable "databases" {
  description = "Map of logical service name to MySQL database name"
  type        = map(string)
  default = {
    customer    = "customers_svs"
    catalog     = "catalog_svs"
    appointment = "appointments_svs"
  }
}

variable "master_username" {
  description = "Master MySQL username — used only for initial setup and Vault dynamic secrets config"
  type        = string
  default     = "svs_admin"
  sensitive   = true
}

variable "master_password" {
  description = "Master MySQL password — pass in via TF_VAR_master_password env var, never hardcode"
  type        = string
  sensitive   = true
}
