# galera.sh

# Source in common env vars
# . /vagrant/common.sh

# The routeable IP of the node is on our eth1 interface
ETH1_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
#ETH2_IP=$(ifconfig eth2 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
#ETH3_IP=$(ifconfig eth3 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

# MariaDB
export MYSQL_HOST=$ETH1_IP
export MYSQL_ROOT_PASS=openstack
export MYSQL_DB_PASS=openstack

# Set up MariaDB Repository
apt-get -y install software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
sudo add-apt-repository -y 'deb http://lon1.mirrors.digitalocean.com/mariadb/repo/10.0/ubuntu trusty main'
sudo apt-get update

# Install Packages
DEBIAN_FRONTEND=noninteractive apt-get install -y rsync galera mariadb-galera-server

GALERA_CNF="/etc/mysql/conf.d/galera.cnf"
GALERA1=172.16.0.191
GALERA2=172.16.0.192
GALERA3=172.16.0.193

cat > $GALERA_CNF << EOF
[mysqld]
#mysql settings
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
query_cache_size=0
query_cache_type=0
bind-address=0.0.0.0
#galera settings
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name="my_wsrep_cluster"
wsrep_cluster_address="gcomm://${GALERA1},${GALERA2},${GALERA3}"
wsrep_sst_method=rsync
EOF

service mysql stop


# Sort out keys for root user
if [[ $(hostname -s) == "galera1" ]]
then
	sudo ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
	rm -f /vagrant/id_rsa*
	sudo cp /root/.ssh/id_rsa /vagrant
	sudo cp /root/.ssh/id_rsa.pub /vagrant
fi
cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
sudo cp /vagrant/id_rsa /root/.ssh/id_rsa
chmod 0600 /root/.ssh/id_rsa
