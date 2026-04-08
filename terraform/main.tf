module "networking" {
  source = "./modules/networking"

  cluster_name         = var.cluster_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  environment        = var.environment
  cluster_version    = var.cluster_version
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size

  # Wired directly from networking module outputs
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
}

module "ecr" {
  source = "./modules/ecr"

  environment           = var.environment
  image_retention_count = var.image_retention_count
}

module "rds" {
  source = "./modules/rds"

  environment     = var.environment
  master_username = var.master_username
  master_password = var.master_password

  # Wired from networking module
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  vpc_cidr           = module.networking.vpc_cidr
}

