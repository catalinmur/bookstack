#!/bin/bash
# https://www.nomadproject.io/guides/integrations/consul-connect/index.html

function consul-install() {

############ Installing requirements

sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install curl unzip jq
mkdir -p /etc/consul
mkdir -p /etc/consul.d

############ Creating Consul config file

cat <<EOF | sudo tee /etc/consul/server.hcl
primary_datacenter = "dc1"
client_addr = "${VAGRANT_IP} 10.0.2.15"
bind_addr = "${VAGRANT_IP}"
advertise_addr = "${VAGRANT_IP}"
data_dir = "/var/lib/consul"
datacenter = "dc1"
disable_host_node_id = true
disable_update_check = true
leave_on_terminate = true
log_level = "INFO"
ports = {
  grpc  = 8502
  dns   = 8600
  https = -1
}
connect {
  enabled = true
}
enable_central_service_config = true
protocol = 3
raft_protocol = 3
recursors = [
  "8.8.8.8",
  "8.8.4.4",
]
server_name = "local.consul"
ui = true
EOF

############### Installing Consul 

LATEST_URL=$(curl -sL https://releases.hashicorp.com/consul/index.json | jq -r '.versions[].builds[].url' | egrep -v 'rc|ent|beta' | egrep 'linux.*amd64' | sort -V | tail -1)
wget -q $LATEST_URL -O consul.zip
mkdir -p /usr/local/bin
unzip consul.zip -d /usr/local/bin/ && rm consul.zip

echo -e '\e[38;5;198m'"++++ Installed `/usr/local/bin/consul version`"

######################## Adding Consul Service in systemd

cat <<EOF | sudo tee /lib/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul/server.hcl

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -dev -client="0.0.0.0" -bind="0.0.0.0" -enable-script-checks -config-file=/etc/consul/server.hcl -config-dir=/etc/consul.d -log-file=/var/log/consul.log
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
sudo systemctl start consul
sudo systemctl status consul
sh -c 'sudo tail -f /var/log/consul.log | { sed "/agent: Synced/ q" && kill $$ ;}'
consul join $VAGRANT_IP
consul members
consul info

################# Adding Consul KV

#consul kv put fabio/config/nomad "route add nomad nomad.service.consul:9999/ http://${VAGRANT_IP}:4646"
#consul kv put fabio/config/consul "route add consul consul.service.consul:9999/ http://${VAGRANT_IP}:8500"


echo -e '\e[38;5;198m'"++++ Consul http://$VAGRANT_IP:8500"
}
consul-install