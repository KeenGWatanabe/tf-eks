Another repo
run `tf-backend` for s3 bucket "terraform-state-locks"

This repo
# 1. First apply only the network layer
terraform apply -target=module.vpc

# 2. Wait 2 minutes for VPC stabilization, then apply EKS core
terraform apply -target=module.eks

# 3. Wait 5-10 minutes for EKS control plane, then full apply
terraform apply


# aws
aws eks wait cluster-active --name myapp-eks-cluster --region us-east-1

aws eks update-kubeconfig --name myapp-eks-cluster --region us-east-1


# if you need to Destroy

terraform destroy -target=kubernetes_config_map.aws_auth

terraform destroy -target=module.eks -target=module.vpc