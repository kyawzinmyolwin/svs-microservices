# =============================================================================
# VPC
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # Both required for EKS — allows nodes to resolve internal AWS service
  # endpoints and the EKS API server to reach nodes by DNS
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}


# =============================================================================
# PUBLIC SUBNETS
# Hosts: NAT gateway, load balancers (Kong)
#
# count.index iterates over the availability_zones list, creating one
# subnet per AZ from the matching CIDR in public_subnet_cidrs
# =============================================================================

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # Instances launched here get a public IP automatically
  # Required for NAT gateway and load balancer nodes
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-${var.availability_zones[count.index]}"

    # EKS looks for this tag to know which subnets to place
    # internet-facing load balancers in (e.g. Kong's NLB)
    "kubernetes.io/role/elb" = "1"

    # Tells EKS this subnet belongs to this cluster
    # "shared" means multiple clusters could use it; "owned" means exclusive
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


# =============================================================================
# PRIVATE SUBNETS
# Hosts: EKS worker nodes, RDS MySQL
#
# Nodes in private subnets reach the internet via the NAT gateway,
# but are not directly reachable from outside — correct for production
# =============================================================================

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-private-${var.availability_zones[count.index]}"

    # EKS uses this tag to place internal load balancers (intra-cluster traffic)
    "kubernetes.io/role/internal-elb" = "1"

    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


# =============================================================================
# INTERNET GATEWAY
# Allows traffic between the VPC and the internet.
# Public subnets route 0.0.0.0/0 through this.
# =============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}


# =============================================================================
# ELASTIC IP FOR NAT GATEWAY
# NAT gateway needs a static public IP so outbound traffic from
# private subnets has a consistent source address.
# Useful for whitelisting in external firewalls or RDS security groups.
# =============================================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip"
  }

  # EIP must be created after the IGW is attached to the VPC
  depends_on = [aws_internet_gateway.main]
}


# =============================================================================
# NAT GATEWAY
# Lives in a public subnet. Private subnet nodes send outbound traffic here,
# which NAT translates to the EIP and forwards to the internet.
#
# Single NAT gateway (vs one per AZ) saves ~$100/month in a home lab.
# For production you'd add one per AZ for HA.
# =============================================================================

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Place in first public subnet

  tags = {
    Name = "${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}


# =============================================================================
# ROUTE TABLE — PUBLIC
# Routes all internet-bound traffic through the Internet Gateway
# =============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Associate every public subnet with the public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# =============================================================================
# ROUTE TABLE — PRIVATE
# Routes internet-bound traffic through the NAT gateway.
# Internal VPC traffic (10.0.0.0/16) is routed locally by default.
# =============================================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

# Associate every private subnet with the private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
