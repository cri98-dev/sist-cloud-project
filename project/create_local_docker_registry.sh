#!/bin/bash

. ../config.sh

echo -e "$BLUE[TASK 1] Build Docker images$NC"
cd tap_project
docker compose build
echo -e "done"

echo -e "$BLUE[TASK 2] Create local registry (master:5000)$NC"
docker run -d -p 5000:5000 --restart=always --name registry registry:2
echo -e "done"

echo -e "$BLUE[TASK 3] Push images to local registry (master:5000)$NC"
for img in logstash kafka_server dataset_creator_flask zookeeper spark torchvision_model_flask; do
    docker tag $img master:5000/$img:v1.0
    docker push master:5000/$img:v1.0
    docker image rm $img master:5000/$img:v1.0
done
cd -
echo -e "done"

#cmd to list registry contents
curl master:5000/v2/_catalog