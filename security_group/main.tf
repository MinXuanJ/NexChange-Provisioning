variable "ec2_security_group_name" {}
variable "ec2_jenkins_sg_name" {}
variable "vpc_id" {}  

output "sg_ec2_ssh_http_id" {
  value = aws_security_group.ec2_sg_ssh_http.id
}

output "sg_ec2_jenkins_port_8080_id" {
  value = aws_security_group.ec2_jenkins_sg_name.id
}

resource "aws_security_group" "ec2_sg_ssh_http"{ 
  name = var.ec2_security_group_name
  description = "Enable the Port 22(SSH) & Port 80(http)"
  vpc_id = var.vpc_id

  # SSH for terraform to access the instance remotely
  ingress {
    description = "Allow SSH from anywhere"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  # Enable HTTP & HTTPS
  ingress {
    description = "Allow HTTP from anywhere"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  ingress {
    description = "Allow HTTPS from anywhere"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }
  # Outgoing request
  egress {
    description = "Allow outgoing request"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.ec2_security_group_name
    Environment = "dev"
    IsDefault = "true"
  }
}

resource "aws_security_group" "ec2_jenkins_sg_name" {
  name = var.ec2_jenkins_sg_name
  description = "Allow port 8080 for jenkins"
  vpc_id = var.vpc_id

  # SSH for terraform to access the instance remotely
  ingress {
    description = "Allow SSH from anywhere"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
  }
  tags = {
    Name = var.ec2_jenkins_sg_name
    Environment = "dev"
    IsDefault = "true"
    }
}