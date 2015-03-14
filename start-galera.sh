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

# Add users
USERS="nova
neutron
keystone
glance
cinder
heat"

HAPROXIES="172.16.0.248
172.16.0.249"

# Add HA Proxy User (for checks)
mysql -u root -h localhost -e "GRANT ALL ON *.* to haproxy@\"${H}\";"
mysql -u root -h localhost -e "GRANT ALL ON *.* to root@\"${H}\" IDENTIFIED BY \"openstack\" WITH GRANT OPTION;"

for U in ${USERS}
do
	for H in ${HAPROXIES}
	do
		mysql -u root -h localhost -e "GRANT ALL ON *.* to ${U}@\"${H}\" IDENTIFIED BY \"openstack\";"
	done
done
