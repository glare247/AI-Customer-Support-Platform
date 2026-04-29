# ═══════════════════════════════════════════
# PROJECT
# ═══════════════════════════════════════════
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "sentinel"
}

# ═══════════════════════════════════════════
# VPC
# ═══════════════════════════════════════════
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A (us-east-1a)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B (us-east-1b)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet (us-east-1b)"
  type        = string
  default     = "10.0.2.0/24"
}

# ═══════════════════════════════════════════
# EKS
# ═══════════════════════════════════════════
variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "sentinel-eks-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 3
}