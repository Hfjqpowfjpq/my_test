#!/bin/bash

set -e 
set -o pipefail

cd /root/my_test/
./setup-env.sh
./setup-network.sh
sudo cp -r ymls/* /root/my_test/src/kayobe-config/etc/kayobe
export BASE_PATH="/root/my_test"
source /root/my_test/venvs/kayobe/bin/activate
source /root/my_test/src/kayobe-config/kayobe-env
cd /root/my_test/src
kayobe control host bootstrap
kayobe seed hypervisor host configure
kayobe seed vm provision
kayobe seed host configure --wipe-disks
# RIGHT NOW SEED IP MUST BE ADDED IN ITSELF (JAMMY RELEASE)
ssh ubuntu@192.168.33.5 "echo '127.0.0.1 seed0' | sudo tee -a /etc/hosts"
kayobe seed container image build --push
kayobe seed service deploy
cd /root/my_test/gen-metal
source /root/my_test/venvs/tenks/bin/activate
# Generates virtual bare metal
./tenks-deploy-overcloud.sh 
source /root/my_test/venvs/kayobe/bin/activate
source /root/my_test/src/kayobe-config/kayobe-env
cd /root/my_test/src
kayobe overcloud inventory discover
kayobe overcloud hardware inspect
kayobe overcloud introspection data save
# Se non lo fai non mette img nei nodi bare metal!!
kayobe overcloud host image build
kayobe overcloud provision
kayobe overcloud host configure
# Importante per kolla dato che senno' non riesce a fare pull da local registry!!
kayobe overcloud container image build --push
kayobe overcloud container image pull
kayobe overcloud deployment image build
kayobe overcloud service deploy


