#!/bin/bash

. ./config.sh

# Check config.sh file satisfies the requirements to execute this script.
[[ -z "$FLICKR_API_KEY" ]] && echo -e "${RED}FLICKR_API_KEY env var in $PWD/config.sh is not set. Unable to continue.$NC" && exit
[[ -z "$FLICKR_API_SECRET" ]] && echo -e "${RED}FLICKR_API_SECRET env var in $PWD/config.sh is not set. Unable to continue.$NC" && exit

cluster_config_hosts=$(cat ./azure_cluster_management/cluster_config.sh <(echo "echo \${HOSTNAMES[@]}") | bash)
config_hosts=$(cat ./config.sh <(echo "echo \${HOSTS[@]}") | bash)
[[ $cluster_config_hosts != $config_hosts ]] && echo -e "${RED}$PWD/azure_cluster_management/cluster_config.sh and $PWD/config.sh have different values in HOSTNAMES and HOSTS. Unable to continue.$NC" && exit

cluster_config_user=$(cat ./azure_cluster_management/cluster_config.sh <(echo "echo \$username") | bash)
config_user=$(cat ./config.sh <(echo "echo \$KUSER") | bash)
[[ $cluster_config_user != $config_user ]] && echo -e "${RED}$PWD/azure_cluster_management/cluster_config.sh and $PWD/config.sh have different values in username and KUSER. Unable to continue.$NC" && exit

cluster_config_master=$(cat ./azure_cluster_management/cluster_config.sh <(echo "echo \$master_host") | bash)
config_master=$(cat ./config.sh <(echo "echo \$KMASTER") | bash)
[[ $cluster_config_master != $config_master ]] && echo -e "${RED}$PWD/azure_cluster_management/cluster_config.sh and $PWD/config.sh have different values in master_host and KMASTER. Unable to continue.$NC" && exit

echo "$HOSTS" | grep $KMASTER &>/dev/null || { echo -e "${RED}KMASTER must be in HOSTS array. Unable to continue.$NC"; exit; }



echo -e "$BLUE[TASK 1] Creating VMs cluster$NC"
cd azure_cluster_management
./create-azure-cluster.sh
cd ..


echo -e "$BLUE[TASK 2] Upload scripts to VMs$NC"
./upload_scripts.sh


echo -e "$BLUE[TASK 3] install kube and reboot$NC"
for n in ${HOSTS[@]}; do
    echo -e "$n host..."
    ssh -t $n << EOF
        cd $(basename $PWD)
        sudo su
        ./install_kube.sh
        reboot
EOF
done

echo -e "$BLUE...[Sleeping for 20s (starting at $(date +%T))]...$NC"
sleep 20

echo -e "$BLUE[TASK 4] Boot master$NC"
ssh -t $KMASTER << EOF
    cd $(basename $PWD)
    sudo su
    ./prepare_reset_kube.sh
    ./boot_master.sh
    cd project
EOF


echo -e "$BLUE[TASK 5] Copy joincluster.sh into workers$NC"
./copy_joincluster.sh_into_workers.sh


echo -e "$BLUE[TASK 6] Make workers join k8s cluster$NC"
for n in ${HOSTS[@]}; do
    if [[ $n != "$KMASTER" ]]; then
        ssh -t $n << EOF
            cd $(basename $PWD)
            sudo su
            ./prepare_reset_kube.sh
            ./boot_worker.sh
EOF
    fi
done


echo -e "$BLUE[TASK 7] Create local registry and deploy project$NC"
ssh $KMASTER << EOF
    cd $(basename $PWD)/project

    ./create_local_docker_registry.sh

    sed "s/API_KEY_HERE/$FLICKR_API_KEY/g;s/API_SECRET_HERE/$FLICKR_API_SECRET/g;s/master:/$KMASTER:/g" whole_cloud_project_template.yaml > whole_cloud_project.yaml

    kubectl apply -f whole_cloud_project.yaml

    s=300
    echo -e "$BLUE...[sleeping for \${s}s (starting at \$(date +%T))]...$NC"
    sleep \$s

    echo -e "${BLUE}Executing kubectl port-forward command in background to expose public endpoints$NC"

    while true; do 
        ps -aux | grep forward | grep dataset-creator &>/dev/null || { kubectl port-forward service/dataset-creator --address 0.0.0.0 8081 &>/dev/null & }
        ps -aux | grep forward | grep kibana &>/dev/null || { kubectl port-forward service/kibana --address 0.0.0.0 5601 &>/dev/null & }
        sleep 2
    done &

    echo -e "${GREEN}Use public ip \$(curl ifconfig.me) and ports 8081 (DatasetCreator) and 5601 (Kibana) to interact with the public endpoints of the app!$NC" 
EOF


# così forwardo direttamente all'ip del pod, quindi se il pod cade la regola diventa inutile (cambia l'ip).
# se il pod cade, prima di rieseguire il codice, cancellare tutte le regole generate dall'esecuzione precedente (altrimenti il forwarding non funziona).
# N.B. se si utilizza questo workaround, bisogna eliminare il deploy della network policy in whole_cloud_project.yaml, altrimenti il forwarding non funziona.
# mettendo l'ip del service in -j DNAT, il forwarding non funziona.

    # echo -e "${BLUE}Adding iptables rules to allow DNAT$NC"

    # ip=\$(kubectl get ep dataset-creator -o json | grep ip | cut -d':' -f 2 | tr -d '", ')
    # port=\$(kubectl get ep dataset-creator -o json | grep '"port"' | cut -d':' -f2 | tr -d '", ')
    # echo -e "${GREEN}dataset-creator port: \$port$NC"
    # sudo iptables -t nat -A PREROUTING -p tcp --dport \$port -j DNAT --to-destination \$ip:\$port
    # sudo iptables -A FORWARD -d \$ip -p tcp --dport \$port -j ACCEPT

    # ip=\$(kubectl get ep kibana -o json | grep ip | cut -d':' -f 2 | tr -d '", ')
    # port=\$(kubectl get ep kibana -o json | grep '"port"' | cut -d':' -f2 | tr -d '", ')
    # echo -e "${GREEN}kibana port: \$port$NC"
    # sudo iptables -t nat -A PREROUTING -p tcp --dport \$port -j DNAT --to-destination \$ip:\$port
    # sudo iptables -A FORWARD -d \$ip -p tcp --dport \$port -j ACCEPT

    # sudo iptables -t nat -A POSTROUTING -o vxlan.calico -j MASQUERADE