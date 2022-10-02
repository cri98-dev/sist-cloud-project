#!/usr/bin/env bash

. ./config.sh

# Initialize Kubernetes
echo -e "\n$BLUE[Master] Initialize Kubernetes Cluster$NC"
KADMOPT="--apiserver-advertise-address=$(hostname -i)"
KADMOPT="$KADMOPT --pod-network-cidr=$POD_NETWORK_CIDR"
KADMOPT="$KADMOPT --service-cidr=$SERVICE_CIDR"
rm -f /tmp/kadmfail
(kubeadm init $KADMOPT 2>&1 || touch /tmp/kadmfail) | tee -a /root/kubeinit.log
if [ -f /tmp/kadmfail ] ; then
   echo -e "\n${RED}Failed to start kubeadm (port 10250, etc. in use? some kubelet running?)$NC"
   lsof -i :10250 | tail -1
   echo -e "${RED}check ${REDBG}/root/kubeinit.log$NC${RED} ... exiting$NC"
   exit
fi

echo -e "\n$BLUE[Master] Will now carry out the above instructions for you$NC"

# Copy Kube admin config
echo -e "\n$BLUE[Master] Copy kube admin config to common user's .kube directory$NC"
mkdir -p /home/$KUSER/.kube
cp /etc/kubernetes/admin.conf /home/$KUSER/.kube/config
chown -R $KUSER:$KUSER /home/$KUSER/.kube

# Deploy (SDN) network
echo -e "\n$BLUE[Master] Deploy Calico network$NC"
# curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml -o calico.yaml
# modifiche fatte a mano:
#     CALICO_IPV4POOL_VXLAN da never a always, CALICO_IPV4POOL_IPIP da always a never.
# motivo della modifica:
#     https://projectcalico.docs.tigera.io/reference/public-cloud/azure#about-calico-on-azure --> \
#     "Calico in VXLAN mode is supported on Azure. However, IPIP packets are blocked by the Azure network fabric."

sed "s|192.168.0.0/16|$POD_NETWORK_CIDR|" calico.yaml > calico-${POD_NETWORK_CIDR/\//_}.yaml

chown $KUSER:$KUSER calico-${POD_NETWORK_CIDR/\//_}.yaml

su - $KUSER -c "kubectl create -f $PWD/calico-${POD_NETWORK_CIDR/\//_}.yaml"
# NB: calico.yaml assegna ai Pod che verranno creati gli IP di $POD_NETWORK_CIDR


# Generate Cluster join command
echo -e "\n$BLUE[Master] Generate and save cluster join command to /joincluster.sh$NC"
kubeadm token create --print-join-command > /joincluster.sh
echo cat /joincluster.sh
cat /joincluster.sh

# NB: il token ha una scadenza e va rigenerato se il master diventa "vecchio"
cp /joincluster.sh /tmp
chmod a+r /tmp/joincluster.sh

echo
echo -e "\n$BLUE[Master] Adesso opera da utente $KUSER (${BLUEBG}NON da super-user$NC)"
echo -e   "$BLUE         su questo host, e prova:$NC kubectl get nodes"
