# ═══════════════════════════════════════════
# VPC
# ═══════════════════════════════════════════
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_a_id" {
  description = "Public subnet A ID (us-east-1a)"
  value       = aws_subnet.public.id
}

output "public_subnet_b_id" {
  description = "Public subnet B ID (us-east-1b)"
  value       = aws_subnet.public_b.id
}

output "private_subnet_id" {
  description = "Private subnet ID (us-east-1b)"
  value       = aws_subnet.private.id
}

# ═══════════════════════════════════════════
# EKS
# ═══════════════════════════════════════════
output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = aws_eks_cluster.eks.name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = aws_eks_cluster.eks.endpoint
  sensitive   = true
}

output "eks_cluster_version" {
  description = "EKS Kubernetes version"
  value       = aws_eks_cluster.eks.version
}

output "node_group_name" {
  description = "EKS Node group name"
  value       = aws_eks_node_group.nodes.node_group_name
}

# ═══════════════════════════════════════════
# CONNECT
# ═══════════════════════════════════════════
output "kubectl_connect_command" {
  description = "Run this to connect kubectl to EKS"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.eks.name}"
}

output "ecr_registry" {
  description = "ECR registry URL for pushing images"
  value       = aws_ecr_repository.app.repository_url
}

# ═══════════════════════════════════════════
# ALB CONTROLLER
# ═══════════════════════════════════════════
output "alb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller service account"
  value       = aws_iam_role.alb_controller.arn
}

# ═══════════════════════════════════════════
# NETWORK
# ═══════════════════════════════════════════
output "nat_gateway_ip" {
  description = "NAT Gateway public IP"
  value       = aws_eip.nat.public_ip
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}