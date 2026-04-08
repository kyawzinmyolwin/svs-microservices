# --- Networking ---
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "nat_gateway_ip" {
  description = "NAT gateway public IP"
  value       = module.networking.nat_gateway_ip
}

# --- EKS ---
output "cluster_name" {
  description = "EKS cluster name — use with: aws eks update-kubeconfig --name <value>"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — used for IRSA role bindings"
  value       = module.eks.oidc_provider_arn
}
# --- ECR ---
output "ecr_repository_urls" {
  description = "Map of service name to ECR URL — update your K8s deployments with these"
  value       = module.ecr.repository_urls
}

output "ecr_registry_url" {
  description = "Base ECR registry URL — use for docker login"
  value       = module.ecr.registry_url
}

# --- RDS ---
output "rds_endpoint" {
  description = "RDS endpoint — replaces 192.168.56.1 in your ConfigMaps"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.port
}

output "rds_connection_string" {
  description = "MySQL connection string (no password)"
  value       = module.rds.connection_string
  sensitive   = true
}
