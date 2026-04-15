# IAM Role and Web Identity Provider for GitHub Actions
# Create an IAM Role for GitHub Actions with a trust relationship to the OIDC provider
resource "aws_iam_role" "tf_github_actions_role" {
  name               = "github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy.json
}