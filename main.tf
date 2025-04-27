module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.36.0" # Replace with the latest version available
  cluster_name    = "myapp-eks-cluster"
  cluster_version = "1.32" # Update as needed
  cluster_endpoint_public_access = true
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets # Dynamically include public subnets
  cluster_additional_security_group_ids = [aws_security_group.eks.id] 
  cluster_endpoint_public_access_cidrs = ["119.74.93.41/32"]
  
   eks_managed_node_groups = {
    eks-node-group = {
      min_capacity     = 1
      max_capacity     = 3
      desired_capacity = 2
      instance_types   = ["t3.medium"]
      capacity_type    = "ON_DEMAND" 

      # Required for aws-auth ConfigMap
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
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
  depends_on = [
    module.eks,
    module.eks.eks_managed_node_groups  # Wait for node groups
  ]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML- rolearn: ${module.eks.eks_managed_node_groups["eks-node-group"].iam_role_arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
YAML

    mapUsers = <<YAML
- userarn: arn:aws:iam::255945442255:user/roger_ce9
  username: roger_ce9
  groups:
    - system:masters
YAML
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.region
    ]
  }
}