#Variable set for IAM Assume Role Module
variable "github_actions_role_name" {
  description = "The name of the IAM role for GitHub Actions"
  type        = string
  default     = "github-actions-role"
}
variable "identifier" {
  description = "The identifier for the OIDC provider"
  type        = string
  default     = "arn:aws:iam::AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"

}
variable "github_repo" {
  description = "GitHub Repo Information"
  type        = string
  default     = "repo:github_user_account/repo_name:*"
}
variable "policy_arn" {
  description = "Policy ARN"
  type        = string
  default     = "arn:aws:iam::AWS_ACCOUNT_ID:policy/policy_name"
}