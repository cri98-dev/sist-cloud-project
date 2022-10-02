#!/bin/bash

. ./cluster_config.sh

for n in ${HOSTNAMES[@]}; do
  ip=$(az network public-ip show \
          --resource-group $group  \
          --name "${n}-ip" \
          --query ipAddress \
          --output tsv)
  echo -e "$n: $ip"
done