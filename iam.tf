# resource "aws_iam_role" "eks_role" {
#   name = "${local.prefix}-eks-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#       }
#     ]
#   })
#   force_detach_policies = true
# }



# # ---IAM trust policy---
# data "aws_iam_policy_document" "eks_assume_role_policy" {
#   statement {
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["eks.amazonaws.com"]
#     }
#     actions = ["sts:AssumeRole"]
#   } 
# }

# # ---IAM permissions policy---
# data "aws_iam_policy_document" "eks_policy" {
#   statement {
#     effect    = "Allow"
#     actions   = [
#       "eks:DescribeCluster",
#       "eks:CreateCluster",
#       "eks:DeleteCluster",
#       "eks:ListClusters",
#       "ec2:DescribeInstances",
#       "iam:PassRole",
#       "autoscaling:DescribeAutoScalingGroups"
#     ]
#     resources = ["*"] # Adjust this for security best practices
#   }
# }

# resource "aws_iam_policy" "eks_policy" {
#   name   = "eks-cluster-policy"
#   policy = data.aws_iam_policy_document.eks_policy.json
# }

# # Attach cluster policy permissions
# resource "aws_iam_role_policy_attachment" "eks_attach_policy" {
#   role       = aws_iam_role.eks_role.name
#   policy_arn = aws_iam_policy.eks_policy.arn
# }

# # Attach control plane permissions
# resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
#   role       = aws_iam_role.eks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# # Attach service policy for EKS
# resource "aws_iam_role_policy_attachment" "eks_service_policy" {
#   role       = aws_iam_role.eks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
# }

# # Attach worker node permissions
# resource "aws_iam_role_policy_attachment" "eks_node_policy" {
#   role       = aws_iam_role.eks_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }
