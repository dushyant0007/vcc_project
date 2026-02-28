# Set the default provider (virtualbox, vmware_desktop, libvirt)
provider = 'virtualbox'

# Set the number of worker nodes
NUM_TARGET=2
# Set default RAM and CPU values (worker nodes)
RAM_SIZE=1024
CPU_COUNT=2
# Set the default RAM and CPU values (control node)
CONTROL_RAM_SIZE=1024
CONTROL_CPU_COUNT=1

# if exists, upload this public key to the VMs
KEY_FILE_PATH = File.join(Dir.pwd, "key", "vcc_key.pub")

# Set the network configuration (prefixes)
WORKLOAD_NET = "192.168.255"
STORAGE_NET  = "10.10.255"

# Set the box name and version
BOX = "enricorusso/VCCubuntu"
BOX_VERSION = "24.04.3"

Vagrant.configure("2") do |config|
  config.vm.box = BOX
  config.vm.box_version = BOX_VERSION

  config.vm.hostname = "default"
  config.vm.synced_folder ".", "/vagrant" # , disabled: true


  config.vm.provider "virtualbox" do |vb|
    # vb.gui = true
    vb.memory = RAM_SIZE
    vb.cpus = CPU_COUNT
  end

  (1..NUM_TARGET).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}"

      # adds new network card to vm with fixed ip and mac
      node.vm.network "private_network", ip: "#{WORKLOAD_NET}.1#{i}", mac: "DEADBEEF000#{i}"
      node.vm.network "private_network", ip: "#{STORAGE_NET}.1#{i}",  mac: "CAFEBABE000#{i}"


      if File.exist?(KEY_FILE_PATH)
        node.vm.provision :file, :source => "#{KEY_FILE_PATH}", :destination => "/tmp/id.pub"

        # if any one log_in using this key don't give them sudo permissions.
        node.vm.provision :shell, :inline => "cat /tmp/id.pub >> ~vagrant/.ssh/authorized_keys", :privileged => false
      end

      (1..NUM_TARGET).each do |i|
        node.vm.provision :shell, :inline => "grep #{WORKLOAD_NET}.1#{i} /etc/hosts || echo '#{WORKLOAD_NET}.1#{i} node#{i}.vcc.local node#{i}' >> /etc/hosts"
      end

      node.vm.provision :shell, :inline => "grep #{STORAGE_NET}.10 /etc/hosts || echo '#{STORAGE_NET}.10 storage.vcc.local storage' >> /etc/hosts"
    end
  end

  config.vm.define "control" do |control|

    control.vm.hostname = "controlnode"

    control.vm.network "private_network", ip: "#{WORKLOAD_NET}.10", mac: "DEADBEEF000C"
    control.vm.network "private_network", ip: "#{STORAGE_NET}.10",  mac: "CAFEBABE000C"


    if File.exist?(KEY_FILE_PATH)
      control.vm.provision :file, :source => "#{KEY_FILE_PATH}", :destination => "/tmp/id.pub"
      control.vm.provision :shell, :inline => "cat /tmp/id.pub >> ~vagrant/.ssh/authorized_keys", :privileged => false
    end

    control.vm.provision :shell, :inline => "apt-get update; apt-get -y install ansible sshpass make"
    control.vm.provision :shell, :inline => "test -f /home/vagrant/.ssh/id_rsa || ssh-keygen -f /home/vagrant/.ssh/id_rsa -q -P \"\"", :privileged => false
    control.vm.provision :shell, :inline => "grep #{WORKLOAD_NET}.10 /etc/hosts || echo '#{WORKLOAD_NET}.10 controlnode.vcc.local controlnode' >> /etc/hosts"
    control.vm.provision :shell, :inline => "grep #{STORAGE_NET}.10 /etc/hosts || echo '#{STORAGE_NET}.10 storage.vcc.local storage' >> /etc/hosts"
    control.vm.provision :shell, :inline => "echo -e '[defaults]\nhost_key_checking = False' >> ~/.ansible.cfg", :privileged => false

    (1..NUM_TARGET).each do |i|
      control.vm.provision :shell, :inline => "sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f vagrant@#{WORKLOAD_NET}.1#{i}", :privileged => false
      control.vm.provision :shell, :inline => "grep #{WORKLOAD_NET}.1#{i} /etc/hosts || echo '#{WORKLOAD_NET}.1#{i} node#{i}.vcc.local node#{i}' >> /etc/hosts"
    end
  end
end