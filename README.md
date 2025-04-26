
terraform apply -target=module.vpc -target=module.eks  # First create VPC + EKS

terraform apply  # Then add the ConfigMap


aws eks update-kubeconfig --name myapp-eks-cluster --region us-east-1
