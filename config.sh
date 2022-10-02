### ATTENZIONE, in "V=DEF" NO SPAZI PRIMA E DOPO "=" ###

RED='\033[0;31;1m'
BLUE='\033[0;34;1m'
GREEN='\033[0;32;1m'
REDBG='\033[0;41;1m'
BLUEBG='\033[0;44;1m'
GREENBG='\033[0;42;1m'
NC='\033[0m'


FLICKR_API_KEY=
FLICKR_API_SECRET=

KVERS=1.23.10-00

KMASTER="master" # must match "master_host" env var value in ./azure_cluster_management/cluster_config.sh 
HOSTS=($KMASTER worker1 worker2) # must match "HOSTNAMES" array in ./azure_cluster_management/cluster_config.sh 

# si presume su ognuno degli host vi sia l'utente $KUSER
# che utilizzera` k8s e che, dal cliente, rsync permetta
# di inviare file agli host (v. upload_scripts.sh)
KUSER="cavia"

# blocco di IP allocato per la rete dei Pod
POD_NETWORK_CIDR="192.168.0.0/16"

# blocco CIDR allocato per gli IP "virtuali" dei servizi
SERVICE_CIDR="172.96.0.0/16"


