output "repository_urls" {
  description = "Map of service name to ECR repository URL — use these in your Kubernetes deployments and GitHub Actions push steps"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "registry_id" {
  description = "AWS account ID — used as the ECR registry ID for docker login"
  value       = data.aws_caller_identity.current.account_id
}

output "registry_url" {
  description = "Base ECR registry URL — use for docker login command"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com"
}
