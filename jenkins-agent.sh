#!/bin/bash

#resize disk from 20GB to 50GB
growpart /dev/nvme0n1 4

lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -L +10G /dev/mapper/RootVG-rootVol
lvextend -l +100%FREE /dev/mapper/RootVG-homeVol

xfs_growfs /
xfs_growfs /var
xfs_growfs /home

set -euxo pipefail

# ----------------------------------------------------
# Base OS update
# ----------------------------------------------------
dnf update -y

# ----------------------------------------------------
# Java (Jenkins Agent requirement)
# Java 17 is sufficient and stable
# ----------------------------------------------------
dnf install -y java-17-openjdk

# ----------------------------------------------------
# Node.js 20 (safe method for RHEL 9)
# ----------------------------------------------------
dnf module disable nodejs -y
dnf module enable nodejs:20 -y
dnf install -y nodejs

# ----------------------------------------------------
# Docker
# ----------------------------------------------------
dnf install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

# Allow ec2-user to run Docker
usermod -aG docker ec2-user

# ----------------------------------------------------
# Terraform
# ----------------------------------------------------
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform

# ----------------------------------------------------
# Trivy
# ----------------------------------------------------
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sh -s -- -b /usr/local/bin

# ----------------------------------------------------
# Maven
# ----------------------------------------------------
dnf install -y maven

# ----------------------------------------------------
# Python
# ----------------------------------------------------
dnf install -y python3 python3-pip gcc python3-devel

# ----------------------------------------------------
# Helm
# ----------------------------------------------------
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

# ----------------------------------------------------
# kubectl
# ----------------------------------------------------
curl -Lo /usr/local/bin/kubectl \
  https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.2/2025-11-13/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl

# ----------------------------------------------------
# eksctl
# ----------------------------------------------------
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
install -m 0755 /tmp/eksctl /usr/local/bin/eksctl
rm -f eksctl_$PLATFORM.tar.gz /tmp/eksctl

# ----------------------------------------------------
# Validation log
# ----------------------------------------------------
echo "Jenkins Agent setup completed successfully"
