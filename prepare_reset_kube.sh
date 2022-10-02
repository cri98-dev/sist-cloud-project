#!/usr/bin/env bash

. ./config.sh

# Enable docker service
echo -e "\n$BLUE[TASK 1] Enable and restart docker service$NC"
# docker service must be started and enabled
systemctl enable docker
systemctl restart docker

# Check sysctl settings
echo -e "\n$BLUE[TASK 2] Check sysctl settings$NC"

sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.bridge.bridge-nf-call-iptables
echo -e "if two previous lines do not end in '... = 1', check sysctl setting in install_kube.sh"

# Disable swap
echo -e "\n$BLUE[TASK 3] Turn off SWAP$NC"
#sed -i '/swap/d' /etc/fstab
swapoff -a

# Reset kubernetes software
echo -e "\n$BLUE[TASK 4] Reset k8s, remove some config files, stop kubelet service$NC"
rm -rf /etc/kubernetes/*
mkdir -p /etc/kubernetes/manifests
rm -rf /var/lib/etcd

kubeadm reset -f
echo -e "\n$(basename $0): Removing /etc/cni/net.d\n"
rm -rf /etc/cni/net.d
#systemctl enable kubelet
systemctl stop kubelet
# kubelet serve solo sui worker (vedi script)

lsof -i :10250 && echo -e "\n${REDBG}port 10250 busy, maybe should stop microk8s?$NC" && exit

echo -e "${GREEN}Now run ./boot_master.sh or ./boot_worker.sh$NC"
