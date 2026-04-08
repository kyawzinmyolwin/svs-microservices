output "cluster_name" {
  description = "EKS cluster name — used to configure kubectl and Helm provider"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint — used by kubernetes and helm providers"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA — used by kubernetes and helm providers"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = aws_eks_cluster.main.version
}

output "node_group_role_arn" {
  description = "IAM role ARN of worker nodes — referenced in aws-auth ConfigMap"
  value       = aws_iam_role.node_group.arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — used to create IRSA roles for service accounts"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL — used to build IRSA trust policy conditions"
  value       = aws_iam_openid_connect_provider.cluster.url
}
