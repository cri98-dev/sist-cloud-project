#!/usr/bin/env bash

if [[ "$1" = "-h" || "x$1" != "x-n"  && "x$1" != "x--dry-run" && "x" != "x$1" ]] ; then
   echo -e "Usage: $0 [-n|--dry-run|-h]"
   echo -e "x$1"
   exit
fi


. ./config.sh


FILES="*.sh *.yaml"

echo -e "\n${BLUE}Upload degli script sugli host ${HOSTS[@]} $NC"
echo -e "${BLUE}(futuri worker e master k8s)$NC"

for srv in ${HOSTS[@]} ; do
   if [[ $srv != "$KMASTER" ]]; then
      rsync $1 -Ptu -e "ssh -o StrictHostKeyChecking=no" $FILES $srv:$(basename $PWD)/ ;
   else
      rsync $1 -r -Ptu -e "ssh -o StrictHostKeyChecking=no" $FILES "project" $srv:$(basename $PWD)/ ;
   fi
done

echo -e "\n${BLUE}Su ognuno degli host (${BLUEBG}${HOSTS[@]}${NC}${BLUE}), $NC"
echo -ne "${BLUE}gli script si trovano in $NC"
echo -e "${BLUEBG}/home/$KUSER$NC$BLUE \n(si presume ${BLUEBG}$KUSER$BLUE sia un utente su ogni host)$NC"
echo -e "${BLUE}dentro la directory $BLUEBG$(basename $PWD)$NC"