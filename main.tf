module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.36.0" # Replace with the latest version available
  cluster_name    = "${local.prefix}-eks-cluster"
  cluster_version = "1.32" # Update as needed
  cluster_endpoint_public_access = true
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets # Dynamically include public subnets
  cluster_additional_security_group_ids = [aws_security_group.eks.id] 
  cluster_endpoint_public_access_cidrs = ["119.74.93.41/32"]
  
   eks_managed_node_groups = {
    eks-node-group = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.medium"]
      capacity_type    = "ON_DEMAND" 
    }
  }

  tags = {
    Environment = "Production"
    Project     = local.prefix
  }
}

# Add after the EKS module
locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [module.eks]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.eks_role.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
YAML
    mapUsers = <<YAML
- userarn: arn:aws:iam::${local.aws_account_id}:user/roger_ce9  # ← Replace with your IAM username
  username: admin
  groups:
    - system:masters
YAML
  }

  
}
