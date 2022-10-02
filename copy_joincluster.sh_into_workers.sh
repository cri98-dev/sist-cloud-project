#!/bin/bash

. ./config.sh

src_path=/tmp/joincluster.sh
dest_path=$src_path

for n in ${HOSTS[@]}; do
    if [[ $n != "master" ]]; then
        scp -3 master:$src_path $n:$dest_path
    fi
done