# =============================================================================
# DB SUBNET GROUP
# Tells RDS which subnets it can place instances in.
# Must span at least 2 AZs — we give it all 3 private subnets.
# RDS will sit in private subnets only — no direct internet access.
# =============================================================================

resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-db-subnet-group"
  description = "Private subnets for SVS RDS instance"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}


# =============================================================================
# SECURITY GROUP — RDS
# Only allows MySQL traffic (port 3306) from within the VPC.
# EKS pods reach RDS via the VPC CIDR — no public access at all.
#
# This replaces the host-level MySQL on 192.168.56.1 from your Vagrant setup.
# The key difference: no credentials in ConfigMaps pointing to a host IP.
# =============================================================================

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Allow MySQL access from within VPC only"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MySQL from VPC - EKS pods and Vault reach RDS through here"
  }

  # No egress needed for RDS — it only responds, never initiates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}


# =============================================================================
# PARAMETER GROUP
# Configures the MySQL engine settings.
# Using MySQL 8.0 — matches your existing schema and Vault database plugin.
#
# Key setting: require_secure_transport = 0
# Allows Vault's database secrets engine to connect without SSL for now.
# In production you'd enforce SSL and provide certs to Vault.
# =============================================================================

resource "aws_db_parameter_group" "main" {
  name        = "${var.environment}-mysql8"
  family      = "mysql8.0"
  description = "SVS MySQL 8.0 parameter group"

  parameter {
    name  = "require_secure_transport"
    value = "0"
  }

  # Vault dynamic secrets engine creates and drops users frequently.
  # Lower wait_timeout prevents stale connections from accumulating.
  parameter {
    name  = "wait_timeout"
    value = "300"
  }

  tags = {
    Name = "${var.environment}-mysql8"
  }
}


# =============================================================================
# RDS INSTANCE — MySQL 8.0
#
# Single instance (not Multi-AZ) — appropriate for a home lab / portfolio.
# Multi-AZ doubles the cost for HA you don't need here.
#
# db.t3.micro is Free Tier eligible for the first 12 months of a new account.
# 20GB gp2 storage is also within Free Tier limits.
#
# master_username / master_password:
#   This is the admin account used ONLY for:
#     1. Initial schema creation
#     2. Vault's database secrets engine config (to create/revoke dynamic users)
#   Your Flask apps never use this account — they use Vault-generated creds.
# =============================================================================

resource "aws_db_instance" "main" {
  identifier = "${var.environment}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = 100 # Auto-scaling upper limit — prevents runaway growth
  storage_type          = "gp2"
  storage_encrypted     = true # Encrypts data at rest — good portfolio practice

  db_name  = "svs" # Initial default DB — individual service DBs created via schema SQL
  username = var.master_username
  password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.main.name

  # No public access — pods reach RDS via private VPC routing only
  publicly_accessible = false

  # Single AZ — saves ~$15/month vs Multi-AZ for a home lab
  multi_az = false

  # Automated backups — 7 day retention, runs at low-traffic time (NZT midnight)
  backup_retention_period = 7
  backup_window           = "12:00-13:00" # UTC = NZT midnight

  # Maintenance window — Sunday 2am NZT
  maintenance_window = "Sun:14:00-Sun:15:00" # UTC

  # Prevents accidental deletion — you must set this to false before
  # terraform destroy will actually remove the RDS instance
  deletion_protection = false # Keep false for home lab — easier to destroy

  # Skip final snapshot on destroy — saves time and cost in a home lab
  # Set to true in production
  skip_final_snapshot = true

  tags = {
    Name = "${var.environment}-mysql"
  }
}
