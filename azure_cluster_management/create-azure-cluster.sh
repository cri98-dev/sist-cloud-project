#!/bin/bash

. ./cluster_config.sh

# Check all values in "HOSTNAMES", "SUBNETS" and "NSGS" have corresponding values in associative arrays.
for h in ${HOSTNAMES[@]}; do
  echo "${!vmNamesToSizes[@]}" | grep $h &>/dev/null || { echo -e "${RED}Not all hosts in HOSTNAMES array have a correspondig value in vmNamesToSizes array. Unable to continue.$NC"; exit; }
  echo "${!vmNamesToSubnets[@]}" | grep $h &>/dev/null || { echo -e "${RED}Not all hosts in HOSTNAMES array have a correspondig value in vmNamesToSubnets array. Unable to continue.$NC"; exit; }
done

for h in ${SUBNETS[@]}; do
  echo "${!subnetNamesToPrefixes[@]}" | grep $h &>/dev/null || { echo -e "${RED}Not all subnets in SUBNETS array have a correspondig value in subnetNamesToPrefixes array. Unable to continue.$NC"; exit; }
  echo "${!subnetNamesToNsgs[@]}" | grep $h &>/dev/null || { echo -e "${RED}Not all subnets in SUBNETS array have a correspondig value in subnetNamesToNsgs array. Unable to continue.$NC"; exit; }
done

for h in ${NSGS[@]}; do
  echo "${!nsgNamesToPorts[@]}" | grep $h &>/dev/null || { echo -e "${RED}Not all nsgs in NSGS array have a correspondig value in nsgNamesToPorts array. Unable to continue.$NC"; exit; }
done


[[ -f $logs_file ]] && rm $logs_file

mkdir -p $KEYS_PARENT_DIR


echo -e "$BLUE[TASK 1] Create ssh keys (locally)$NC"
for n in ${!KEY_PATHS[@]}; do
  if [[ ! -f "${KEY_PATHS[$n]}" ]]; then
    ssh-keygen \
      -m PEM \
      -t rsa \
      -b 4096 \
      -C "$username@$n" \
      -f "${KEY_PATHS[$n]}" \
      -N ""
  fi
done
echo -e "done"


echo -e "$BLUE[TASK 2] Restrict key files permissions (chmod 400)$NC"
chmod 400 ${KEY_PATHS[@]}
echo -e "done"


echo -e "$BLUE[TASK 3] Create $group group in $location location$NC"
az group create \
  --name $group \
  --location $location |& tee -a $logs_file \
|& grep -i '"provisioningState": "Succeeded"' &>/dev/null && echo -e "${GREEN}Success$NC" || echo -e "${RED}Failed. Check $logs_file file for more details$NC"


echo -e "$BLUE[TASK 4] Create $vnetName ($vnetPrefix) vnet$NC"
az network vnet create \
  --name $vnetName \
  --resource-group $group \
  --address-prefix $vnetPrefix |& tee -a $logs_file \
|& grep -i '"provisioningState": "Succeeded"' &>/dev/null && echo -e "${GREEN}Success$NC" || echo -e "${RED}Failed. Check $logs_file file for more details$NC"


echo -e "$BLUE[TASK 5] Create nsgs...$NC"
for n in ${NSGS[@]}; do
  echo -e "${BLUE}Creating $n nsg...$NC"
  az network nsg create \
    --resource-group $group \
    --name $n \
    --location $location |& tee -a $logs_file \
  |& grep -i '"provisioningState": "Succeeded"' &>/dev/null && echo -e "${GREEN}Success$NC" || echo -e "${RED}Failed. Check $logs_file file for more details$NC"

  priority=300
  for p in ${nsgNamesToPorts[$n]}; do
    echo -e "${BLUE}Adding rule to allow traffic towards port $p to $n nsg$NC"
    az network nsg rule create \
      --resource-group $group \
      --nsg-name $n \
      --name Allow-$p-All \
      --access Allow \
      --protocol TCP \
      --direction Inbound \
      --priority $priority \
      --source-address-prefix Internet \
      --source-port-range "*" \
      --destination-address-prefix "*" \
      --destination-port-range $p |& tee -a $logs_file \
    |& grep -i '"provisioningState": "Succeeded"' &>/dev/null && echo -e "${GREEN}Success$NC" || echo -e "${RED}Failed. Check $logs_file file for more details$NC"
    priority=$((priority+10))
  done
done


echo -e "$BLUE[TASK 6] Create subnets$NC"
for subnet in ${SUBNETS[@]}; do
  echo -e "${BLUE}Creating $subnet (${subnetNamesToPrefixes[$subnet]}) subnet in $vnetName vnet, associating it to ${subnetNamesToNsgs[$subnet]} nsg...$NC"
  az network vnet subnet create \
    --resource-group $group \
    --vnet-name $vnetName \
    --name $subnet \
    --address-prefixes ${subnetNamesToPrefixes[$subnet]} \
    --network-security-group ${subnetNamesToNsgs[$subnet]} |& tee -a $logs_file \
  |& grep -i '"provisioningState": "Succeeded"' &>/dev/null && echo -e "${GREEN}Success$NC" || echo -e "${RED}Failed. Check $logs_file file for more details$NC"
done


echo -e "$BLUE[TASK 7] Create VMs$NC"
for vmName in ${HOSTNAMES[@]}; do
  echo -e "${BLUE}Creating $vmName VM related resources...$NC"

  echo -e "${BLUE}Creating ${vmName}-ip public ip$NC"
  az network public-ip create \
    --resource-group $group \
    --name "${vmName}-ip" \
    --version IPv4 \
    --sku $pubIpSku |& tee -a $logs_file \
  |& grep -i '"provisioningState": "Succeeded"' &>/dev/null && echo -e "${GREEN}Success$NC" || echo -e "${RED}Failed. Check $logs_file file for more details$NC"

  echo -e "${BLUE}Creating ${vmName}-nic nic (binding it to ${vmNamesToSubnets[$vmName]} subnet and ${vmName}-ip public ip)$NC"
  az network nic create \
    --resource-group $group \
    --name "${vmName}-nic" \
    --vnet-name $vnetName \
    --subnet ${vmNamesToSubnets[$vmName]} \
    --public-ip-address "${vmName}-ip" \
    --accelerated-networking true |& tee -a $logs_file \
  |& grep -i '"provisioningState": "Succeeded"' &>/dev/null && echo -e "${GREEN}Success$NC" || echo -e "${RED}Failed. Check $logs_file file for more details$NC"

  echo -e "${BLUE}Creating $vmName VM...$NC"
  az vm create \
    --resource-group $group \
    --name $vmName \
    --admin-username $username \
    --authentication-type ssh \
    --ssh-key-values "${KEY_PATHS[$vmName]}.pub" \
    --nics "${vmName}-nic" \
    --nic-delete-option Delete \
    --image $image \
    --size ${vmNamesToSizes[$vmName]} \
    --os-disk-size-gb 64 \
    --os-disk-delete-option Delete \
    --storage-sku $storageSku \
    --public-ip-sku $pubIpSku |& tee -a $logs_file \
  |& grep -i '"powerState": "VM running"' &>/dev/null && echo -e "${GREEN}Success$NC" || echo -e "${RED}Failed. Check $logs_file file for more details$NC"
done


echo -e "$BLUE[TASK 8] Create new ~/.ssh/config file$NC"
mkdir -p ~/.ssh/old_config_files
[[ -f ~/.ssh/config ]] && mv ~/.ssh/config ~/.ssh/old_config_files/config.$RANDOM

for n in ${HOSTNAMES[@]}; do
  cat >> ~/.ssh/config << EOF
  Host $n
    HostName $(az network public-ip show --resource-group $group --name $n-ip --query ipAddress --output tsv)
    User cavia
    IdentityFile ${KEY_PATHS[$n]}

EOF
done
echo -e "done"

echo -e "${GREEN}To ssh into VMs, simply type 'ssh <vm-name>'!$NC"