# Define AWS provider
provider "aws" {
  region = "us-east-2"  # Replace with your desired region
}

# Create an EKS cluster
resource "aws_eks_cluster" "cluster" {
  name     = "ashish"  # Replace with your desired cluster name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = ["subnet-0cc71f36f26b6b03a", "subnet-01da053285ed1019b"]  # Replace with your subnet IDs
    security_group_ids = ["sg-089c907eb24429082"]  # Replace with your security group ID
  }
}

# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"  # Replace with your desired role name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM role policy attachment for EKS cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM role for EKS nodes
resource "aws_iam_role" "eks_node_role" {
  name               = "eks-node-role"  # Replace with your desired role name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM role policy attachments for EKS nodes
resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Kubernetes provider
provider "kubernetes" {
  config_context_cluster = aws_eks_cluster.cluster.name

  load_config_file = false
}

# Kubernetes deployment
resource "kubernetes_deployment" "fortune" {
  metadata {
    name = "fortune-api"
    labels = {
      app = "fortune-api"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "fortune-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "fortune-api"
        }
      }

      spec {
        container {
          image = "637423421797.dkr.ecr.us-east-2.amazonaws.com/devops-fortune-api:latest"  # Replace with your ECR image URL
          name  = "fortune-api"
          port {
            container_port = 8080  # Replace with your container port
          }
        }
      }
    }
  }
}

# Kubernetes service
resource "kubernetes_service" "fortune" {
  metadata {
    name = "fortune-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.fortune.spec.0.template.0.metadata.0.labels.app
    }

    port {
      port        = 80  # Service port
      target_port = 8080  # Container port
    }

    type = "LoadBalancer"
  }
}
