variable "bucket_name" {
  type        = string
  description = "Remote state bucket name"
}

variable "env_prefix" {
  type        = string
  description = "Prefix of environment"
}
variable "vpc_cidr" {
  type        = string
  description = "Public Subnet CIDR values"
}

variable "vpc_name" {
  type        = string
  description = "NexChange VPC"
}

variable "cidr_public_subnet" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "cidr_private_subnet" {
  type        = list(string)
  description = "Private Subnet CIDR values"
}

variable "availability_zone" {
  type        = list(string)
  description = "Availability Zones"
}

variable "ec2_ami_id" {
  type        = string
  description = "AMI ID for EC2"
}

variable "public_key" {
  type        = string
  description = "Public Key for EC2"
}

variable "private_key_local_address" {
  type = string
  description = "Local Private Key Address for EC2 Connection"
}

variable "cluster_name" {
  type = string
  description = "Name of EKS Cluster"
}