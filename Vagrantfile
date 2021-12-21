# -*- mode: ruby -*-
# vi: set ft=ruby :

# create local domain name e.g user.local.dev
user = ENV["USER"].downcase
fqdn = ENV["fqdn"] || "local"

vbox_config = [
  { '--memory' => '4096' },
  { '--cpus' => '2' },
  { '--cpuexecutioncap' => '100' },
  { '--largepages' => 'on' },
  { '--natdnshostresolver1' => 'on' },
  { '--natdnsproxy1' => 'on' },
]

# machine(s) hash
machines = [
  {
    :name => "app.#{fqdn}",
    :ip => '192.168.56.210',
    :ssh_port => '2255',
    :disksize => '10GB',
    :vbox_config => vbox_config,
    :synced_folders => [
      { :vm_path => '/data', :ext_rel_path => '../../', :vm_owner => 'ubuntu' },
    ],
  },
]


Vagrant::configure("2") do |config|

  machines.each_with_index do |machine, index|

    config.vm.box = "ubuntu/bionic64"
    config.vm.define machine[:name] do |config|

      config.disksize.size = machine[:disksize]
      config.ssh.forward_agent = true
      config.ssh.insert_key = true
      config.vm.network "private_network", ip: machine[:ip]
      config.vm.network "forwarded_port", guest: 22, host: machine[:ssh_port], id: 'ssh', auto_correct: true
        config.vm.network "forwarded_port", guest: 4646, host: 4646 # nomad
        config.vm.network "forwarded_port", guest: 8500, host: 8500 # consul
        config.vm.network "forwarded_port", guest: 8600, host: 8600, protocol: 'udp' # consul dns
        config.vm.network "forwarded_port", guest: 3306, host: 3306 # mysql
        config.vm.network "forwarded_port", guest: 6875, host: 6875 # bookstack

      config.vm.hostname = "#{machine[:name]}"

      unless machine[:vbox_config].nil?
        config.vm.provider :virtualbox do |vb|
          machine[:vbox_config].each do |hash|
            hash.each do |key, value|
              vb.customize ['modifyvm', :id, "#{key}", "#{value}"]
            end
          end
        end
      end


      # vagrant up --provision-with bootstrap to only run this on vagrant up
      config.vm.provision "bootstrap", preserve_order: true, type: "shell", privileged: true, inline: <<-SHELL
        echo -e '\e[38;5;198m'"BEGIN BOOTSTRAP $(date '+%Y-%m-%d %H:%M:%S')"
        echo -e '\e[38;5;198m'"running vagrant as #{user}"
        echo -e '\e[38;5;198m'"vagrant IP "#{machine[:ip]}
        echo -e '\e[38;5;198m'"vagrant fqdn #{machine[:name]}"
        echo -e '\e[38;5;198m'"vagrant index #{index}"
        cd ~\n
        grep -q "VAGRANT_IP=#{machine[:ip]}" /etc/environment
        if [ $? -eq 1 ]; then
          echo "VAGRANT_IP=#{machine[:ip]}" >> /etc/environment
        else
          sed -i "s/VAGRANT_INDEX=.*/VAGRANT_INDEX=#{index}/g" /etc/environment
        fi
        grep -q "VAGRANT_INDEX=#{index}" /etc/environment
        if [ $? -eq 1 ]; then
          echo "VAGRANT_INDEX=#{index}" >> /etc/environment
        else
          sed -i "s/VAGRANT_INDEX=.*/VAGRANT_INDEX=#{index}/g" /etc/environment
        fi
        # install applications
        export DEBIAN_FRONTEND=noninteractive
        export PATH=$PATH:/root/.local/bin
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes update -o Acquire::CompressionTypes::Order::=gz
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes upgrade
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install swapspace jq curl unzip software-properties-common bzip2 git make python3-pip python3-dev python3-virtualenv golang-go apt-utils
        sudo -E -H pip3 install pip --upgrade
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes autoremove
        sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes clean
        sudo rm -rf /var/lib/apt/lists/partial
      SHELL

      # install docker
      config.vm.provision "docker", preserve_order: true, type: "shell", path: "scripts/docker.sh"

      # install consul
      config.vm.provision "consul", type: "shell", preserve_order: true, privileged: true, path: "scripts/consul.sh"

      # install nomad
      # vagrant up --provision-with nomad to only run this on vagrant up
      config.vm.provision "nomad", type: "shell", preserve_order: true, privileged: true, path: "scripts/nomad.sh"

      # vagrant up --provision-with bootstrap to only run this on vagrant up
      config.vm.provision "welcome", preserve_order: true, type: "shell", privileged: true, inline: <<-SHELL
        echo -e '\e[38;5;198m'"Consul http://localhost:8500"
        echo -e '\e[38;5;198m'"Nomad http://localhost:4646"
        echo -e '\e[38;5;198m'"Bookstack http://localhost:6875"
      SHELL

    end
  end
end
