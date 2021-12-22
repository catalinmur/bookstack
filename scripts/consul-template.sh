#!/bin/bash
# https://github.com/hashicorp/consul-template

####### Installing Consul-template

LATEST_URL=$(curl -sL https://releases.hashicorp.com/consul-template/index.json | jq -r '.versions[].builds[].url' | egrep -v 'rc|ent|beta' | egrep 'linux.*amd64' | sort -V | tail -1)
wget -q $LATEST_URL -O consultemplate.zip
mkdir -p /usr/local/bin
unzip consultemplate.zip -d /usr/local/bin/ && rm consultemplate.zip

