module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.36.0" # Replace with the latest version available
  cluster_name    = "${local.prefix}-eks-cluster"
  cluster_version = "1.32" # Update as needed
  vpc_id          = aws_vpc.main.id
  subnet_ids      = aws_subnet.public[*].id # Dynamically include public subnets


   eks_managed_node_groups = {
    eks-node-group = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }

  tags = {
    Environment = "Production"
    Project     = local.prefix
  }
}
