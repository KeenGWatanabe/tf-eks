terraform {
  backend "s3" {
    bucket         = "rgers3.tfstate-backend.com"  # Must match the bucket name above
    key            = "infra/terraform.tfstate"        # State file path
    region         = "us-east-1"                # Same as provider
    dynamodb_table = "terraform-state-locks"    # If using DynamoDB
    # use_lockfile   = true                       # replaces dynamodb_table                
    encrypt        = true                       # Use encryption
  }
}
provider "aws" {
  region = var.region # Change if needed
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {  # <-- This was missing
  state = "available"
}

locals {
  prefix = "myapp" # Change to your preferred prefix
 }

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${local.prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2) # Use 2 AZs
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"] # For internal EKS nodes

  enable_nat_gateway   = true
  single_nat_gateway   = true # Cost optimization
  enable_dns_hostnames = true # Required for EKS

  # Critical for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "Production"
    Project     = local.prefix
  }
}

# --- VPC & Networking ---

# --- Security Group for EKS  ---
resource "aws_security_group" "eks" {
  name        = "${local.prefix}-eks-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow inbound HTTP traffic"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["119.74.93.41/32"] # Restrict in production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Remove all the manual IAM role/policy resources - let the EKS module handle these
# --- IAM role ---
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "cluster_endpoint" {
  description = "EKS control plane endpoint"
  value       = module.eks.cluster_endpoint
}
