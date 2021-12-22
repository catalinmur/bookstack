#!/bin/bash
# https://github.com/hashicorp/consul-template

####### Installing Consul-template

LATEST_URL=$(curl -sL https://releases.hashicorp.com/consul-template/index.json | jq -r '.versions[].builds[].url' | egrep -v 'rc|ent|beta' | egrep 'linux.*amd64' | sort -V | tail -1)
wget -q $LATEST_URL -O consultemplate.zip
mkdir -p /usr/local/bin
unzip consultemplate.zip -d /usr/local/bin/ && rm consultemplate.zip

########### Adding Consul KVs

consul kv put config/vagrant_ip `echo $VAGRANT_IP`
consul kv put config/database/name bookstackapp
consul kv put config/database/pass dbpass
consul kv put config/database/user bookstack
consul kv put config/database/root_pass rootpass

############## Getting templates
mkdir /etc/nomad/jobs
curl -so /etc/nomad/jobs/mysql.nomad.ctmpl https://raw.githubusercontent.com/catalinmuraru/bookstack/main/jobs/mysql.nomad
curl -so /etc/nomad/jobs/app.nomad.ctmpl https://raw.githubusercontent.com/catalinmuraru/bookstack/main/jobs/app.nomad

########## Loading Nomad jobs
#nomad plan --address=http://$VAGRANT_IP:4646 /etc/nomad/jobs/mysql.nomad
#nomad run --address=http://$VAGRANT_IP:4646 /etc/nomad/jobs/mysql.nomad
#sleep 5s
#nomad plan --address=http://$VAGRANT_IP:4646 /etc/nomad/jobs/app.nomad
#nomad run --address=http://$VAGRANT_IP:4646 /etc/nomad/jobs/app.nomad
