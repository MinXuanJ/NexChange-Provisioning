variable  "ami_id" {}
variable  "instance_type" {}
variable  "tag_name" {}
variable  "public_key" {}
variable  "subnet_id" {}
variable  "security_group_ids" {}
variable  "associate_public_ip_address" {}
variable  "user_data" {}
variable "private_key_local_address" {}


output "ssh_connection_for_jenkins" {
  value = "ssh -i ${var.private_key_local_address} ubuntu@${aws_instance.jenkins_server.public_ip}"
}

output "jenkins_server_public_ip" {
  value = aws_instance.jenkins_server.public_ip
  description = "The public Elastic IP address of the Jenkins server"
}  

output "jenkins_security_group_id" {
  value = aws_instance.jenkins_server.vpc_security_group_ids
  description = "The security group ID associated with the Jenkins server"
}

output "jenkins_role_arn" {
  value       = data.aws_iam_role.jenkins_role.arn
  description = "The ARN of the Jenkins IAM role"
}

# # 输出Jenkins服务器的实例ID
# output "jenkins_server_instance_id" {
#   value = aws_instance.jenkins_server.id
#   description = "The instance ID of the Jenkins server"
# }

# # 输出Jenkins服务器的子网ID
# output "jenkins_server_subnet_id" {
#   value = aws_instance.jenkins_server.subnet_id
#   description = "The subnet ID of the Jenkins server"
# }

# # 输出Jenkins服务器的安全组
# output "jenkins_server_security_groups" {
#   value = aws_instance.jenkins_server.vpc_security_group_ids
#   description = "The security group IDs associated with the Jenkins server"
# }

# # # 输出挂载的EBS卷ID
# # output "jenkins_server_ebs_volume_id" {
# #   value = aws_ebs_volume.jenkins_server_volume.id
# #   description = "The EBS volume ID attached to the Jenkins server"
# # }

data "aws_iam_role" "jenkins_role" {
  name = "Jenkins_EC2_Role"
}

resource "aws_instance" "jenkins_server" {
  ami = var.ami_id
  instance_type = var.instance_type
  associate_public_ip_address = var.associate_public_ip_address
  subnet_id = var.subnet_id
  key_name = "NexChange-dev-devops-key"
  vpc_security_group_ids = var.security_group_ids
  user_data = var.user_data
  iam_instance_profile = "Jenkins_EC2_Role"

  tags = {
    Name = "NexChange Jenkins Server: Ubuntu EC2"
  }
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
  }
}




resource "aws_key_pair" "jenkins_server_public_key" {
  key_name = "NexChange-dev-devops-key"
  public_key = var.public_key
}

# resource "aws_eip" "jenkins_server_eip" {
#   domain = "vpc"
# }

# resource "aws_eip_association" "jenkins_server_eip_association" {
#   instance_id = aws_instance.jenkins_server.id
#   allocation_id = aws_eip.jenkins_server_eip.id
# }

resource "aws_ebs_volume" "jenkins_server_volume" {
  availability_zone = aws_instance.jenkins_server.availability_zone
  size = 20
  tags = {
    Name = "Jenkins Server Volume"
  }
}

resource "aws_volume_attachment" "jenkins_server_volume_attachment" {
  device_name = "/dev/sdh"
  volume_id = aws_ebs_volume.jenkins_server_volume.id
  instance_id = aws_instance.jenkins_server.id

  depends_on = [aws_instance.jenkins_server]
}
