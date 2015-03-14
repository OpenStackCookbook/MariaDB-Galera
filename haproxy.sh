# haproxy.sh

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

# Install Packages
DEBIAN_FRONTEND=noninteractive apt-get install -y haproxy

HAPROXY_CFG="/etc/haproxy/haproxy.cfg"
GALERA1=172.16.0.191
GALERA2=172.16.0.192
GALERA3=172.16.0.193

cat > $HAPROXY_CFG << EOF
global
  log 127.0.0.1   local0
  log 127.0.0.1   local1 notice
  #log loghost    local0 info
  maxconn 4096
  #chroot /usr/share/haproxy
  user haproxy
  group haproxy
  daemon
  #debug
  #quiet

defaults
  log global
  mode http
  option tcplog
  option dontlognull
  retries 3
  option redispatch
  maxconn 4096
  timeout connect 50000ms
  timeout client 50000ms
  timeout server 50000ms

listen  mysql 0.0.0.0:3306
  mode tcp
  balance roundrobin
  option tcpka
  option mysql-check user haproxy
  server mysql1 $GALERA1:3306 weight 1
  server mysql2 $GALERA2:3306 weight 1
  server mysql3 $GALERA3:3306 weight 1
EOF

sudo sed -i 's/^ENABLED.*/ENABLED=1/' /etc/default/haproxy
sudo service haproxy start

# Keepalived
sudo apt-get -y install keepalived

echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
sysctl -p

cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_script chk_haproxy {
  script "killall -0 haproxy" # verify the pid exists or
    not
  interval 2        # check every 2 seconds
  weight 2          # add 2 points if OK
}

vrrp_instance VI_1 {
  interface eth1    # interface to monitor
  state MASTER
  virtual_router_id 51  # Assign one ID for this route
  priority 101      # 101 on master, 100 on backup
  virtual_ipaddress {
    172.16.0.251   # the virtual IP
  }
  track_script {
    chk_haproxy
  }
}
EOF

sudo service keepalived start

cat /vagrant/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
sudo cp /vagrant/id_rsa /root/.ssh/id_rsa
chmod 0600 /root/.ssh/id_rsa
