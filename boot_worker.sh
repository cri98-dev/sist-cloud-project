#!/usr/bin/env bash

. ./config.sh

systemctl is-active kubelet --quiet || systemctl restart kubelet

# Join worker nodes to the Kubernetes cluster
echo -e "$BLUE[Worker] Join node to Kubernetes Cluster$NC"

cp -puf /tmp/joincluster.sh /joincluster.sh
[ -r /joincluster.sh ] && bash /joincluster.sh || echo no /joincluster.sh ; exit

MASTER=$(cut -d' ' -f3 /joincluster.sh | cut -d':' -f1)

echo -e "$BLUE[Master] Adesso opera da utente $KUSER (${BLUEBG}NON da super-user$NC)"
echo -e "${BLUE}e sul master host ($MASTER) prova:$NC  kubectl get nodes"

