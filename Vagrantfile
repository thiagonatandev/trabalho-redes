# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider 'virtualbox' do |v|
      v.memory = 2048 
      v.cpus = 2
  end

  config.vm.provision 'shell', path: 'scripts/setup.sh'
end