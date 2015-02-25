#!/bin/bash

GALERA1=172.16.0.191
GALERA2=172.16.0.192
GALERA3=172.16.0.193

sudo ssh-keyscan $GALERA1 >> ~/.ssh/known_hosts
sudo ssh root@$GALERA1 "service mysql start --wsrep-new-cluster"
sleep 5
sudo ssh-keyscan $GALERA2 >> ~/.ssh/known_hosts
sudo ssh root@$GALERA2 "service mysql start"
sleep 5
sudo ssh-keyscan $GALERA3 >> ~/.ssh/known_hosts
sudo ssh root@$GALERA3 "service mysql start"
