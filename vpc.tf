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
  region = "us-east-1" # Change if needed
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {  # <-- This was missing
  state = "available"
}

locals {
  prefix = "myapp" # Change to your preferred prefix
 }



# --- VPC & Networking ---
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${local.prefix}-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${local.prefix}-public-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.prefix}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${local.prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Security Group for EKS  ---
resource "aws_security_group" "eks" {
  name        = "${local.prefix}-eks-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow inbound HTTP traffic"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict in production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

resource "aws_iam_policy" "eks_policy" {
  name   = "eks-cluster-policy"
  policy = data.aws_iam_policy_document.eks_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_attach" {
  role       = aws_iam_role.eks_role.name
  policy_arn = aws_iam_policy.eks_policy.arn
}
