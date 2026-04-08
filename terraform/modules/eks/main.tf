# =============================================================================
# IAM ROLE — EKS CLUSTER
# The control plane assumes this role to manage AWS resources on your behalf
# (e.g. creating load balancers, describing EC2 instances)
# =============================================================================

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.cluster_name}-cluster-role"
  }
}

# AWS-managed policies required by the EKS control plane
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# =============================================================================
# IAM ROLE — EKS NODE GROUP
# Worker nodes assume this role to pull images from ECR, write logs to
# CloudWatch, and register with the cluster
# =============================================================================

resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.cluster_name}-node-role"
  }
}

# Three AWS-managed policies required by EKS worker nodes
resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Allows nodes to pull container images from ECR
# Your svs-microservices images will be pushed to ECR in the next phase
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# =============================================================================
# SECURITY GROUP — CLUSTER CONTROL PLANE
# Controls traffic between the EKS control plane and worker nodes
# =============================================================================

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster control plane security group"
  vpc_id      = var.vpc_id

  # Allow all outbound — control plane needs to reach nodes and AWS APIs
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# =============================================================================
# SECURITY GROUP — WORKER NODES
# Controls traffic to/from EC2 worker nodes
# =============================================================================

resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "EKS worker node security group"
  vpc_id      = var.vpc_id

  # Nodes can talk to each other freely (required for pod-to-pod traffic)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow node-to-node communication"
  }

  # Control plane can reach nodes on kubelet port and webhook ports
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description     = "Allow control plane to reach nodes"
  }

  # Allow all outbound — nodes need to reach ECR, S3, and AWS APIs
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-nodes-sg"
    # EKS requires this tag to discover node security groups
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Allow cluster control plane to reach nodes on HTTPS (required for webhooks
# — Vault Agent injector uses mutating webhooks to inject sidecars)
resource "aws_security_group_rule" "cluster_to_nodes_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.nodes.id
  description              = "Allow control plane webhooks (required for Vault sidecar injection)"
}


# =============================================================================
# EKS CLUSTER
# The control plane — managed by AWS, you pay ~$0.10/hr for this
# =============================================================================

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)

    security_group_ids = [aws_security_group.cluster.id]

    # API server accessible from outside VPC (needed for kubectl from your machine)
    endpoint_public_access  = true

    # Restrict to private access inside VPC as well
    endpoint_private_access = true
  }

  # Ship control plane logs to CloudWatch — useful for debugging auth issues
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]

  tags = {
    Name = var.cluster_name
  }
}


# =============================================================================
# EKS MANAGED NODE GROUP
# AWS manages the EC2 instances — handles patching, replacement, and scaling
# Nodes are placed in private subnets (no direct internet exposure)
# =============================================================================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node_group.arn

  # Private subnets only — nodes are not directly internet-accessible
  subnet_ids = var.private_subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  # Allow rolling updates — replaces nodes one at a time during upgrades
  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly,
  ]

  tags = {
    Name = "${var.cluster_name}-nodes"
  }
}


# =============================================================================
# IRSA — IAM ROLES FOR SERVICE ACCOUNTS
# This is the AWS-native equivalent of what you built with Vault Kubernetes auth.
# Instead of Vault validating the ServiceAccount JWT, AWS IAM does it directly.
#
# How it works:
#   1. EKS exposes an OIDC endpoint
#   2. You register it with AWS IAM as a trusted identity provider
#   3. Pods annotated with an IAM role ARN can assume that role via STS
#   4. No static credentials needed — exactly like your Vault dynamic secrets
#
# You'll use this for:
#   - Vault pods accessing AWS KMS (Auto-Unseal — a future improvement)
#   - App pods accessing AWS Secrets Manager (your Option 4)
# =============================================================================

# Fetch the OIDC thumbprint — AWS needs this to trust the EKS OIDC provider
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-oidc"
  }
}
