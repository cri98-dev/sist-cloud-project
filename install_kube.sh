#!/usr/bin/env bash

. ./config.sh


# Install apt-transport-https pkg
echo -e "$BLUE[TASK 2] Installing apt-transport-https pkg$NC"
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo -e "$BLUE[TASK 3] Install docker container engine$NC"
apt-get install ca-certificates software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install docker-ce docker-ce-cli docker-compose-plugin -y

# add account to the docker group
usermod -aG docker $KUSER

# Enable docker service
echo -e "$BLUE[TASK 4] Enable and start docker service$NC"
systemctl enable docker >/dev/null 2>&1
systemctl start docker


echo -e "$BLUE[TASK 5] Create /etc/docker/daemon.json file$NC"
# Docker container engine should be installed and enabled
# Qui si presume lo sia, ma con il driver di default, quindi
# si installa  il driver overlay2, raccomandato per kubernetes
cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "insecure-registries": [ "$KMASTER:5000" ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
# Restart Docker (dopo la prima volta non dovrebbe servire)
systemctl daemon-reload
systemctl restart docker

# Con sysctl cambia in /proc/sys i setting necessari per
# consentire ai Pod sull'host di comunicare tra loro,
# almeno in certe condizioni (non so se ci riguardino, ma...)
echo -e "$BLUE[TASK 6] Add sysctl settings$NC"
if ! grep -q net.bridge.bridge-nf-call-ip6tables /etc/sysctl.d/kubernetes.conf; then
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
EOF
fi

if ! grep -q net.bridge.bridge-nf-call-iptables /etc/sysctl.d/kubernetes.conf; then
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-iptables = 1
EOF
fi

# ma i sysctl precedenti sono attivi solo se c'è il modulo br_netfilter
echo br_netfilter > /etc/modules-load.d/br_nf_kube.conf
modprobe br_netfilter
# modprobe serve all'installazione, poi il modulo viene caricato al boot
sysctl --system
# precedente serve all'installazione, poi viene effettuato al boot

# Add the kubernetes sources list into the sources.list directory
echo -e "$BLUE[TASK 7] Add the k8s sources list$NC"
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
ls -ltr /etc/apt/sources.list.d/kubernetes.list
apt-get update -y

# Install Kubernetes
echo -e "$BLUE[TASK 8] Install Kubernetes kubeadm, kubelet and kubectl$NC"
apt-get install -y kubelet=$KVERS kubeadm=$KVERS kubectl=$KVERS
kubeadm completion bash > /etc/bash_completion.d/kubeadm
kubectl completion bash > /etc/bash_completion.d/kubectl
