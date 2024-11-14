variable "vpc_cidr"{}
variable "vpc_name" {}
variable "cidr_public_subnet" {}
variable "availability_zone" {}
variable "cidr_private_subnet" {}
variable "env_prefix" {}

output "vpc_id" {
  value       = aws_vpc.NexChange_dev_vpc_1_sg.id
  description = "The ID of the VPC"
}

output "public_subnets_ip" {
  value       = aws_subnet.NexChange_dev_public_subtets[*].id
  description = "The IPs of the public subnet" 
}

output "private_subnets_id" {
  value = aws_subnet.NexChange_dev_private_subtets[*].id
  description = "The IDs of the private subnet"
}

# Setup VPC
resource "aws_vpc" "NexChange_dev_vpc_1_sg" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.env_prefix}-${var.vpc_name}"
    Environment = "dev"
    IsDefault = "true"
  }
}

# Setup Public Subnet
resource "aws_subnet" "NexChange_dev_public_subtets" {
  count = length(var.cidr_public_subnet)
  vpc_id = aws_vpc.NexChange_dev_vpc_1_sg.id
  cidr_block = element(var.cidr_public_subnet, count.index)
  availability_zone = element(var.availability_zone, count.index)
  
  tags = {
    Name = "NexChange_dev_public_subnet_${count.index+1}"
    Environment = "dev"
    IsDefault = "true"
  }
}

# Setup Private Subnet
resource "aws_subnet" "NexChange_dev_private_subtets" {
  count = length(var.cidr_private_subnet)
  vpc_id = aws_vpc.NexChange_dev_vpc_1_sg.id
  cidr_block = element(var.cidr_private_subnet, count.index)
  availability_zone = element(var.availability_zone, count.index)
  tags = {
    Name = "NexChange_dev_private_subnet_${count.index+1}"
    Environment = "dev"
    IsDefault = "true"
  }
}

# Setup Internet Gateway
resource "aws_internet_gateway" "NexChange_dev_igw" {
  vpc_id = aws_vpc.NexChange_dev_vpc_1_sg.id
  tags = {
    Name = "NexChange_dev_igw"
    Environment = "dev"
    IsDefault = "true"
  }
}
# Setup EIP
resource "aws_eip" "NexChange_dev_eip" {
  vpc = true
}

# Set up NAT
resource "aws_nat_gateway" "NexChange_dev_nat" {
  allocation_id = aws_eip.NexChange_dev_eip.id
  subnet_id = element(aws_subnet.NexChange_dev_public_subtets[*].id, 0)
}

# Setup Public Route Table
resource "aws_route_table" "NexChange_dev_public_route_table" {
  vpc_id = aws_vpc.NexChange_dev_vpc_1_sg.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.NexChange_dev_igw.id
  }
  tags = {
    Name = "NexChange_dev_public_route_table"
    Environment = "dev"
    IsDefault = "true"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "NexChange_dev_public_route_table_subnet_association" {
  count = length(aws_subnet.NexChange_dev_public_subtets)
  subnet_id = element(aws_subnet.NexChange_dev_public_subtets[*].id, count.index)
  route_table_id = aws_route_table.NexChange_dev_public_route_table.id
}

# Private Route Table
resource "aws_route_table" "NexChange_dev_private_route_table" {
  vpc_id = aws_vpc.NexChange_dev_vpc_1_sg.id
  route { 
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NexChange_dev_nat.id
  }

  tags = {
    Name = "NexChange_dev_private_route_table"
    Environment = "dev"
    IsDefault = "true"
  }
}

# Private Subnet RouteTable Association
resource "aws_route_table_association" "NexChange_dev_private_route_table_subnet_association" {
  count = length(aws_subnet.NexChange_dev_private_subtets)
  subnet_id = aws_subnet.NexChange_dev_private_subtets[count.index].id
  route_table_id = aws_route_table.NexChange_dev_private_route_table.id
}

