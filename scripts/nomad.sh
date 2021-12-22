#!/bin/bash

function nomad-install() {

########### Installing Requirements
sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install curl unzip jq
yes | sudo docker system prune -a
yes | sudo docker system prune --volumes

########### Creating nomad config file
mkdir -p /etc/nomad
cat <<EOF | sudo tee -a /etc/nomad/server.conf
data_dir  = "/var/lib/nomad"

bind_addr = "0.0.0.0" # the default

datacenter = "dc1"

advertise {
  http = "${VAGRANT_IP}"
  rpc  = "${VAGRANT_IP}"
  serf = "${VAGRANT_IP}:5648" # non-default ports may be specified
}

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
  network_speed = 100
  servers = ["${VAGRANT_IP}:4647"]
  network_interface = "enp0s8"
  options = {
    "docker.volumes.enabled" = true
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

consul {
  address = "${VAGRANT_IP}:8500"
}
EOF

########### Installing Nomad
LATEST_URL=$(curl -sL https://releases.hashicorp.com/nomad/index.json | jq -r '.versions[].builds[].url' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | egrep -v 'rc|beta' | egrep 'linux.*amd64' | sort -V | tail -n 1)
wget -q $LATEST_URL -O /tmp/nomad.zip
mkdir -p /usr/local/bin
(cd /usr/local/bin && unzip /tmp/nomad.zip)
echo -e '\e[38;5;198m'"++++ Installed `/usr/local/bin/nomad version`"

########### Installing CNI Plugins
wget -q https://github.com/containernetworking/plugins/releases/download/v0.8.1/cni-plugins-linux-amd64-v0.8.1.tgz -O /tmp/cni-plugins.tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz
echo 1 > /proc/sys/net/bridge/bridge-nf-call-arptables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
pkill nomad

########### Creating service file

cat <<EOF | sudo tee -a /lib/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

# When using Nomad with Consul it is not necessary to start Consul first. These
# lines start Consul before Nomad as an optimization to avoid Nomad logging
# that Consul is unavailable at startup.
#Wants=consul.service
#After=consul.service

[Service]

# Nomad server should be run as the nomad user. Nomad clients
# should be run as root
#User=nomad
#Group=nomad

ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad/server.conf -dev-connect -log-file=/var/log/nomad.log
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2

## Configure unit start rate limiting. Units which are started more than
## *burst* times within an *interval* time span are not permitted to start any
## more. Use `StartLimitIntervalSec` or `StartLimitInterval` (depending on
## systemd version) to configure the checking interval and `StartLimitBurst`
## to configure how many starts per interval are allowed. The values in the
## commented lines are defaults.

# StartLimitBurst = 5

## StartLimitIntervalSec is used for systemd versions >= 230
# StartLimitIntervalSec = 10s

## StartLimitInterval is used for systemd versions < 230
# StartLimitInterval = 10s

TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable nomad
sudo systemctl start nomad
sudo systemctl status nomad

sh -c 'sudo tail -f /var/log/nomad.log | { sed "/node registration complete/ q" && kill $$ ;}'
nomad server members
nomad node status

mkdir /etc/nomad/jobs
cp jobs/app.nomad /etc/nomad/jobs/
cp jobs/mysql.nomad /etc/nomad/jobs/

nomad plan --address=http://$VAGRANT_IP:4646 /etc/nomad/jobs/mysql.nomad
nomad run --address=http://$VAGRANT_IP:4646 /etc/nomad/jobs/mysql.nomad
sleep 5s
nomad plan --address=http://$VAGRANT_IP:4646 /etc/nomad/jobs/app.nomad
nomad run --address=http://$VAGRANT_IP:4646 /etc/nomad/jobs/app.nomad

echo -e '\e[38;5;198m'"++++ Nomad http://$VAGRANT_IP:4646"
}

nomad-install
