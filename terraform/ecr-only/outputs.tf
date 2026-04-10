output "public_repository_urls" {
  description = "Map of service name to public ECR URL — publicly accessible without authentication"
  value       = { for k, v in aws_ecrpublic_repository.services : k => "public.ecr.aws/${v.repository_name}" }
}

output "public_registry_url" {
  description = "Public ECR registry base URL"
  value       = "public.ecr.aws"
}

output "registry_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
