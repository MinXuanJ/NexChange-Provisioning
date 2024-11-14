module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  cidr_public_subnet   = var.cidr_public_subnet
  availability_zone = var.availability_zone
  cidr_private_subnet  = var.cidr_private_subnet
  env_prefix           = var.env_prefix
}

module "security_group" {
  source                  = "./security_group"
  vpc_id                  = module.networking.vpc_id
  ec2_security_group_name = "SG for EC2 to enable SSH(22), HTTPS(443) and HTTP(80)"
  ec2_jenkins_sg_name     = "Allow port 8080 for jenkins"
}

module "jenkins" {
  source            = "./jenkins"
  ami_id            = var.ec2_ami_id
  instance_type     = "t2.medium"
  tag_name          = "NexChange Jenkins Server: Ubuntu EC2"
  public_key        = var.public_key
  subnet_id         = tolist(module.networking.public_subnets_ip)[0]
  security_group_ids = [module.security_group.sg_ec2_ssh_http_id, module.security_group.sg_ec2_jenkins_port_8080_id]
  associate_public_ip_address  = true
  user_data         = templatefile("./jenkins-runner-script/jenkins-installer.sh", {})
  private_key_local_address = var.private_key_local_address
}



module "eks" {
  source = "./eks"
  vpc_id = module.networking.vpc_id
  private_subnets_id = module.networking.private_subnets_id
  cluster_version = var.cluster_version
  cluster_name = var.cluster_name
  jenkins_role_arn = module.jenkins.jenkins_role_arn
  jenkins_security_group_ids = [module.security_group.sg_ec2_ssh_http_id, module.security_group.sg_ec2_jenkins_port_8080_id]
}


output "vpc_id" {
  value = module.networking.vpc_id
  description = "The value of VPC id"
}

output "jenkins_server_public_ip" {
  value = module.jenkins.jenkins_server_public_ip
  description = "value of jenkins server public ip"
}

output "ssh_connection_for_jenkins" {
  value = module.jenkins.ssh_connection_for_jenkins
  description = "SSH connection for jenkins"
}
