provider "kubernetes" {
  host                   = aws_eks_cluster.NexChange_dev_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.NexChange_dev_eks_cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.NexChange_dev_eks_cluster.name]
    command     = "aws"
  }
}

variable "cluster_name" {}
variable "vpc_id" {}
variable "private_subnets_id" {}
variable "cluster_version" {}
variable "jenkins_role_arn" {}
variable "jenkins_security_group_ids" {}
  

resource "aws_eks_cluster" "NexChange_dev_eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.NexChange_dev_eks_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.private_subnets_id
    endpoint_private_access = true
    endpoint_public_access = true
    public_access_cidrs = [ "0.0.0.0/0" ]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.NexChange_dev_eks_cluster_policy,
    aws_iam_role_policy_attachment.NexChange_dev_eks_service_policy,
  ]
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks_cluster_sg"
  description = "Security group for EKS Cluster"
  vpc_id      = var.vpc_id

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Jenkins EC2 to access EKS API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = var.jenkins_security_group_ids
  }
  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([{
      rolearn  = aws_iam_role.NexChange_dev_eks_node_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = var.jenkins_role_arn
      username = "jenkins"
      groups   = ["system:masters"]
    }])
  }

  depends_on = [aws_eks_cluster.NexChange_dev_eks_cluster]
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "NexChange_dev_eks_role" {
  name = "NexChange_dev_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "NexChange_dev_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.NexChange_dev_eks_role.name
}

resource "aws_iam_role_policy_attachment" "NexChange_dev_eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.NexChange_dev_eks_role.name
}


# Node Group Resource for EKS
resource "aws_eks_node_group" "NexChange_dev_eks_node_group" {
  cluster_name    = aws_eks_cluster.NexChange_dev_eks_cluster.name
  node_group_name = "NexChange_dev_eks_node_group"
  node_role_arn   = aws_iam_role.NexChange_dev_eks_node_role.arn
  subnet_ids      = var.private_subnets_id

  scaling_config {
    desired_size = 3    # Adjust the desired number of nodes
    max_size     = 5    # Adjust the maximum number of nodes
    min_size     = 1    # Adjust the minimum number of nodes
  }

  instance_types = ["t3.medium"] # Specify the instance types for the nodes

  depends_on = [
    aws_iam_role_policy_attachment.NexChange_dev_eks_worker_node_policy,
    aws_iam_role_policy_attachment.NexChange_dev_eks_cni_policy,
    aws_iam_role_policy_attachment.NexChange_dev_eks_ecr_policy,
  ]
}

# IAM Role for the Node Group
resource "aws_iam_role" "NexChange_dev_eks_node_role" {
  name = "NexChange_dev_eks_node_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# Attach necessary policies to the Node Role
resource "aws_iam_role_policy_attachment" "NexChange_dev_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.NexChange_dev_eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "NexChange_dev_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.NexChange_dev_eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "NexChange_dev_eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.NexChange_dev_eks_node_role.name
}


