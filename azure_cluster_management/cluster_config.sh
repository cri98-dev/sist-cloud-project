#!/bin/bash


#------------------------------------script vars------------------------------

RED='\033[0;31;1m'
BLUE='\033[0;34;1m'
GREEN='\033[0;32;1m'
REDBG='\033[0;41;1m'
BLUEBG='\033[0;44;1m'
GREENBG='\033[0;42;1m'
NC='\033[0m'

logs_file="cluster-creation.logs"

#---------------------------------------------------------------------------------------

#-------------------------------------azure cluster vars--------------------------------

# non metto i nomi direttamente nell'array perché così l'eventuale modifica dei nomi delle vm, grazie all'uso delle variabili, \
# si ripercuote anche sugli array associativi, in automatico.
master_host="master"
worker1_host="worker1"
worker2_host="worker2"
HOSTNAMES=($master_host $worker1_host $worker2_host) # Gli host in questo array sono gli host che verranno effettivamente creati.
frontendSubnetName="frontend-subnet"
backendSubnetName="backend-subnet"
SUBNETS=($frontendSubnetName $backendSubnetName) # Le subnet in questo array sono le subnet che verranno effettivamente create.
frontendNsgName="frontend-nsg"
backendNsgName="backend-nsg"
NSGS=($frontendNsgName $backendNsgName) # Gli nsg in questo array sono gli nsg che verranno effettivamente creati.
group="cavia-group"
location="francecentral"
vnetName="cavia-vnet"
vnetPrefix="10.0.0.0/16"
image="Canonical:UbuntuServer:18_04-lts-gen2:latest"
storageSku="StandardSSD_LRS"
pubIpSku="Standard"
username="cavia"

declare -A subnetNamesToPrefixes

subnetNamesToPrefixes[$frontendSubnetName]="10.0.1.0/24"
subnetNamesToPrefixes[$backendSubnetName]="10.0.2.0/24"

declare -A subnetNamesToNsgs

subnetNamesToNsgs[$frontendSubnetName]=$frontendNsgName
subnetNamesToNsgs[$backendSubnetName]=$backendNsgName

declare -A nsgNamesToPorts

nsgNamesToPorts[$frontendNsgName]="22 5601 8081"
nsgNamesToPorts[$backendNsgName]="22"

declare -A vmNamesToSizes

vmNamesToSizes[$master_host]="Standard_D2as_v4"
vmNamesToSizes[$worker1_host]="Standard_D2as_v4"
vmNamesToSizes[$worker2_host]="Standard_D2s_v3"

declare -A vmNamesToSubnets

vmNamesToSubnets[$master_host]=$frontendSubnetName
vmNamesToSubnets[$worker1_host]=$backendSubnetName
vmNamesToSubnets[$worker2_host]=$backendSubnetName

declare -A KEY_PATHS

KEYS_PARENT_DIR="/home/$USER/.ssh/azure-cluster-keys"

for n in ${HOSTNAMES[@]}; do
  KEY_PATHS[$n]="${KEYS_PARENT_DIR}/${n}_key"
done

#---------------------------------------------------------------------------------------



