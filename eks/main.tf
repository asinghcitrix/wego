# Specify the AWS provider
provider "aws" {
  region = "us-east-2"  # Replace with your desired AWS region
}

# IAM Role for EKS Service
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"  # Replace with your desired role name

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# VPC Configuration (Optional - customize as needed)
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"  # Replace with your desired CIDR block

  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_subnet" "eks_subnet" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.1.0/24"  # Replace with your desired subnet CIDR block
  availability_zone = "us-east-2a"  # Replace with your desired AZ

  tags = {
    Name = "eks-subnet"
  }
}

resource "aws_security_group" "eks_security_group" {
  vpc_id = aws_vpc.eks_vpc.id

  // Define security group rules as needed
}

# Amazon EKS Cluster Resource
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"  # Replace with your desired cluster name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.eks_subnet.id]
    security_group_ids = [aws_security_group.eks_security_group.id]
  }

  tags = {
    Environment = "Production"  # Replace with appropriate tags
  }
}
