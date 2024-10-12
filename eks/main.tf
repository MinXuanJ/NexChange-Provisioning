# variable "cluster_name" {}
# variable "vpc_id" {}

# resource "aws_eks_cluster" "NexChange_dev_eks_cluster" {
#   name     = var.cluster_name
#   role_arn = aws_iam_role.NexChange_dev_eks_role.arn
#   vpc_config {
#     subnet_ids = module.networking.public_subnets_id
#   }
  
# }