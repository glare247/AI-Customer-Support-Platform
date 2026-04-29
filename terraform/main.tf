# ═══════════════════════════════════════════
# VPC
# ═══════════════════════════════════════════
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name       = "sentinel-vpc"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

# ═══════════════════════════════════════════
# PUBLIC SUBNET A — us-east-1a
# ═══════════════════════════════════════════
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name                                         = "public-subnet-a"
    "kubernetes.io/role/elb"                     = "1"
    "kubernetes.io/cluster/sentinel-eks-cluster" = "shared"
    team                                         = "expandox-lab"
    managed-by                                   = "terraform"
  }
}

# ═══════════════════════════════════════════
# PUBLIC SUBNET B — us-east-1b
# Required for AWS Load Balancer (needs 2 AZs)
# ═══════════════════════════════════════════
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name                                         = "public-subnet-b"
    "kubernetes.io/role/elb"                     = "1"
    "kubernetes.io/cluster/sentinel-eks-cluster" = "shared"
    team                                         = "expandox-lab"
    managed-by                                   = "terraform"
  }
}

# ═══════════════════════════════════════════
# PRIVATE SUBNET — us-east-1b
# EKS nodes run here
# ═══════════════════════════════════════════
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name                                         = "private-subnet"
    "kubernetes.io/role/internal-elb"            = "1"
    "kubernetes.io/cluster/sentinel-eks-cluster" = "shared"
    team                                         = "expandox-lab"
    managed-by                                   = "terraform"
  }
}

# ═══════════════════════════════════════════
# INTERNET GATEWAY
# ═══════════════════════════════════════════
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name       = "sentinel-igw"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

# ═══════════════════════════════════════════
# PUBLIC ROUTE TABLE
# Routes internet traffic through IGW
# Associated with both public subnets
# ═══════════════════════════════════════════
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name       = "public-route-table"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ═══════════════════════════════════════════
# NAT GATEWAY
# Allows private nodes outbound internet access
# ═══════════════════════════════════════════
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name       = "sentinel-nat"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

# ═══════════════════════════════════════════
# PRIVATE ROUTE TABLE
# Routes outbound traffic through NAT
# ═══════════════════════════════════════════
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name       = "private-route-table"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ═══════════════════════════════════════════
# SECURITY GROUP
# ═══════════════════════════════════════════
resource "aws_security_group" "eks_sg" {
  name        = "eks-security-group"
  description = "Allow traffic for EKS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "eks-sg"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

# ═══════════════════════════════════════════
# IAM ROLE — EKS CLUSTER
# ═══════════════════════════════════════════
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ═══════════════════════════════════════════
# EKS CLUSTER
# lifecycle ignore_changes on vpc_config
# EKS does not allow subnet updates after
# cluster creation — managed via lifecycle
# ═══════════════════════════════════════════
resource "aws_eks_cluster" "eks" {
  name     = "sentinel-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public.id,
      aws_subnet.private.id
    ]
    security_group_ids = [aws_security_group.eks_sg.id]
  }

  lifecycle {
    ignore_changes = [
      vpc_config
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name       = "sentinel-eks"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

# ═══════════════════════════════════════════
# IAM ROLE — EKS NODES
# ═══════════════════════════════════════════
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ═══════════════════════════════════════════
# EKS NODE GROUP
# t3.small — works with EKS free tier
# Nodes run in private subnet
# Scaled to 2 for high availability
# ═══════════════════════════════════════════
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "sentinel-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private.id
  ]

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = [var.node_instance_type]

  lifecycle {
    ignore_changes = [
      scaling_config
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.registry_policy
  ]

  tags = {
    Name       = "sentinel-node-group"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

# ═══════════════════════════════════════════
# ECR REPOSITORY
# Stores Docker images built by CI pipeline
# ═══════════════════════════════════════════
resource "aws_ecr_repository" "app" {
  name                 = "ai-platform"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name       = "ai-platform"
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

# ═══════════════════════════════════════════
# OIDC PROVIDER
# Enables IAM Roles for Service Accounts (IRSA)
# Required for AWS Load Balancer Controller
# ═══════════════════════════════════════════
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer

  tags = {
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

# ═══════════════════════════════════════════
# IAM ROLE — AWS LOAD BALANCER CONTROLLER
# IRSA role assumed by the controller pod
# Allows it to manage ALB resources
# ═══════════════════════════════════════════
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "eks-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json

  tags = {
    team       = "expandox-lab"
    managed-by = "terraform"
  }
}

resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/../iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}