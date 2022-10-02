#!/bin/bash

. ./cluster_config.sh

#delete group and every resource it contains:
az group delete \
    --name $group \
    --yes
