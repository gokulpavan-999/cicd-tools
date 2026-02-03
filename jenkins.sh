#!/bin/bash

#resize disk from 20GB to 50GB
growpart /dev/nvme0n1 4

lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -L +10G /dev/mapper/RootVG-rootVol
lvextend -l +100%FREE /dev/mapper/RootVG-homeVol

xfs_growfs /
xfs_growfs /var
xfs_growfs /home


# Exit immediately if any command fails
# -e : exit on error
# -u : error on undefined variables
# -x : print commands (debug)
# -o pipefail : fail if any piped command fails
set -euxo pipefail

# ----------------------------------------------------
# Update OS packages (non-interactive)
# ----------------------------------------------------
yum update -y

# ----------------------------------------------------
# Install required dependencies
# fontconfig + Java 21 required by Jenkins
# yum-utils required for yum-config-manager
# ----------------------------------------------------
yum install -y fontconfig java-21-openjdk yum-utils

# ----------------------------------------------------
# Add Jenkins official repository
# This does NOT ask Y/N in user_data
# ----------------------------------------------------
yum-config-manager --add-repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

# ----------------------------------------------------
# Import Jenkins GPG key explicitly
# Prevents interactive GPG prompt later
# ----------------------------------------------------
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# ----------------------------------------------------
# Clean yum cache and rebuild metadata
# -y ensures NO confirmation prompt
# ----------------------------------------------------
yum clean all -y
yum makecache -y

# ----------------------------------------------------
# Install Jenkins (no Y/N due to -y)
# ----------------------------------------------------
yum install -y jenkins

# ----------------------------------------------------
# Enable and start Jenkins service
# ----------------------------------------------------
systemctl daemon-reexec
systemctl enable jenkins
systemctl start jenkins

# ----------------------------------------------------
# Print initial admin password to cloud-init logs
# (visible in /var/log/cloud-init-output.log)
# ----------------------------------------------------
echo "========== Jenkins Admin Password =========="
cat /var/lib/jenkins/secrets/initialAdminPassword
echo "============================================"
