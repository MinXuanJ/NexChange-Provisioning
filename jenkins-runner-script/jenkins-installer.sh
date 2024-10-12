#!/bin/bash
set -e
set -x

# 日志函数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# 更新系统
log "更新系统..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 安装 Java
if java -version 2>&1 | grep -q "17"; then
    log "JDK 17 已经安装"
else
    log "安装 OpenJDK 17..."
    sudo apt-get install -y openjdk-17-jdk-headless
fi

# 安装 Jenkins
if systemctl is-active --quiet jenkins; then
    log "Jenkins 已安装并正在运行"
else
    log "Jenkins 未安装，正在安装..."
    wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
fi

# 安装 Maven
if mvn -version &>/dev/null; then
    log "Maven 已经安装"
else
    log "安装 Maven..."
    sudo apt-get install -y maven
fi

# 安装 Docker
if docker --version &>/dev/null; then
    log "Docker 已经安装"
else
    log "安装 Docker..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker jenkins
    sudo systemctl enable docker
    sudo systemctl start docker
fi

# 确保 Docker 正在运行
if systemctl is-active --quiet docker; then
    log "Docker 服务正在运行"
else
    log "启动 Docker 服务..."
    sudo systemctl start docker
fi

# 挂载 Jenkins 数据存储卷 (EBS)
if [ -e /dev/sdh ]; then
    if mount | grep -q '/var/lib/jenkins'; then
        log "Jenkins 数据卷已经挂载"
    else
        log "挂载 Jenkins 数据卷"
        sudo mkdir -p /var/lib/jenkins
        sudo mount /dev/sdh /var/lib/jenkins
    fi
else
    log "/dev/sdh 设备不存在，跳过挂载"
fi

# 确保挂载卷可以在重启后自动挂载
if ! grep -q '/dev/sdh /var/lib/jenkins' /etc/fstab; then
    echo "/dev/sdh /var/lib/jenkins ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
fi

# 确保 Jenkins 目录权限正确
sudo chown -R jenkins:jenkins /var/lib/jenkins

# 修改 Jenkins 配置
sudo sed -i 's|JENKINS_HOME=.*|JENKINS_HOME=/var/lib/jenkins|' /etc/default/jenkins

# 安装 Terraform
if ! terraform -v &>/dev/null; then
    log "安装 Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt install -y terraform
else
    log "Terraform 已经安装"
fi

# 重启 Jenkins 服务
log "重启 Jenkins 服务..."
sudo systemctl daemon-reload
sudo systemctl restart jenkins

# 等待 Jenkins 启动
log "等待 Jenkins 启动..."
timeout 120 bash -c 'until sudo systemctl is-active --quiet jenkins; do sleep 2; done'

# 确保 Jenkins 正常运行
if systemctl is-active --quiet jenkins; then
    log "Jenkins 服务正在运行"
else
    log "Jenkins 服务未启动，尝试重新启动..."
    sudo systemctl start jenkins
fi

# 检查已安装的软件版本
log "检查已安装的软件版本..."
java -version
mvn -version
docker --version
terraform -version

# 显示安装结果
log "Jenkins, Maven, Docker, Terraform 已经安装并配置完成。"
