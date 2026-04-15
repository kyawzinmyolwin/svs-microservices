# Output the ARN of the created IAM role
output "github_actions_role_arn" {
  value = aws_iam_role.tf_github_actions_role.arn
}