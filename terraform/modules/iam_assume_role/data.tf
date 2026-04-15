#For Github Actions Runner to assume the role for ECR and EKS access, we need to create an IAM Role with the necessary permissions and a trust relationship to the OIDC provider. This allows the GitHub Actions runner to authenticate and perform actions on AWS resources securely.
data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::366077889879:oidc-provider/token.actions.githubusercontent.com"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:kyawzinmyolwin/svs-microservices:*"]
    }


  }
}
resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.tf_github_actions_role.name
  policy_arn = "arn:aws:iam::366077889879:policy/github-runner-policy"
}