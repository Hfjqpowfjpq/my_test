#!/bin/bash

base_path="/root/my_test"

# Update and Upgrade
sudo apt update && sudo apt -y upgrade

# Install dep
sudo apt -y install git tmux python3-dev gcc libffi-dev python3-venv

# Disable the firewall.
sudo systemctl is-enabled firewalld && sudo systemctl stop firewalld && sudo systemctl disable firewalld

# SELinux setup
#sudo setenforce 0
#sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# Prevent sudo from making DNS queries 
echo 'Defaults  !fqdn' | sudo tee /etc/sudoers.d/no-fqdn

# Gen dirs
mkdir -p src venvs

# Activate and download kayobe
cd $base_path/src
git clone https://opendev.org/openstack/kayobe.git -b stable/2023.2
python3 -m venv $base_path/venvs/kayobe
source $base_path/venvs/kayobe/bin/activate
pip install -U pip
cd $base_path/src/kayobe
pip install .
cd $base_path/src
git clone https://opendev.org/openstack/kayobe-config.git -b stable/2023.2
deactivate

# Activate and download tenks
cd $base_path
git clone https://opendev.org/openstack/tenks.git
python3 -m venv $base_path/venvs/tenks
source $base_path/venvs/tenks/bin/activate
pip install -U pip
cd $base_path/tenks
pip install .
ansible-galaxy install --role-file=requirements.yml --roles-path=ansible/roles/
deactivate

# Setup env for next connections
echo "
cd
source $base_path/venvs/kayobe/bin/activate
source $base_path/src/kayobe-config/kayobe-env" >> /root/.bashrc