
```
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
apt update -y
apt install libguestfs-tools

virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent
qm create 9000 --name "ubuntu-cloud-focal-with-agent" --memory 512 --cores 1 --net0 virtio,bridge=vmbr0
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm 
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000 
```

## Example resource template
This template will work for a standard cloud-init deployment using the ubuntu cloud image as the source template. 
In this case, the template was build using the ubuntu focal cloud image.  Then I cloned a vm from the template and installed the ```qemu-guest-agent``` onto that vm and turned that vm into a template for this resource.  The remote exec will fail without the guest agent because it is impossible for proxmox (and therefore terraform) to know the ip address to use to connect to.  It is possible to set this manually on the ipconfig0 attribute, and hard code it into the connection, but that is less scaleable perhaps.

```
resource "proxmox_vm_qemu" "cloudinit-test01" {
  name        = "clone01"
  desc        = "tf description"
  target_node = "proxmox"
  vmid        = "9001"
  agent = 1
  cores   = 1
  sockets = 1
  memory  = 1024
  ipconfig0 = "ip=192.168.x.x/16,gw=192.168.x.x"
  ciuser      = "username"
  sshkeys     = <<-EOT
                pubkeyhere
                EOT
  clone = "name-of-template-to-clone"
  
  disk {
    type = "scsi"
    storage = "local-lvm"
    size = "32G"
    ssd = 1
  }

  network {
    bridge    = "vmbr0"
    firewall  = true
    model     = "virtio"
  }

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]

    connection {
      type        = "ssh"
      user        = "username"
      private_key = file("path/to/private/key ")
      host        = self.default_ipv4_address
      port        = "22"
    }
  }
}

output "proxmox_ip_address_default01" {
  description = "Current IP Default"
  value = proxmox_vm_qemu.cloudinit-test01.*.default_ipv4_address
}
```

### Creating omada-controller

```
sudo fallocate -l 1G /swap
sudo chmod 600 /swap
sudo mkswap /swap
sudo swapon /swap
sudo cp /etc/fstab /etc/fstab.bak
echo '/swap none swap sw 0 0' | sudo tee -a /etc/fstab
sudo apt install openjdk-8-jre-headless mongodb-server dialog jsvc
sudo systemctl enable --now mongodb
wget https://static.tp-link.com/upload/software/2023/202303/20230321/Omada_SDN_Controller_v5.9.31_Linux_x64.deb
sudo dpkg -i Omada_SDN_Controller_v5.9.31_Linux_x64.deb
```
- Other processes for home use
    - Startup controller and configure site
    - Startup router and configure router manually without changing it's ip (don't try to adopt first)
    - Go to omada controller and then try to adopt using the newly setup username and password
    - Reset all networking equipment (switches, modem, etc.)
    - Verify site settings

### Creating pi-hole server
```
sudo fallocate -l 512M /swap
sudo chmod 600 /swap
sudo mkswap /swap
sudo swapon /swap
sudo cp /etc/fstab /etc/fstab.bak
echo '/swap none swap sw 0 0' | sudo tee -a /etc/fstab
wget -O basic-install.sh https://install.pi-hole.net
sudo bash basic-install.sh
## had to edit netplan dns stuff to get pihole to finish installing.
```

### Creating openvpn server
```
sudo fallocate -l 512M /swap
sudo chmod 600 /swap
sudo mkswap /swap
sudo swapon /swap
sudo cp /etc/fstab /etc/fstab.bak
echo '/swap none swap sw 0 0' | sudo tee -a /etc/fstab
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt update && sudo apt -y install ca-certificates wget net-tools gnupg
wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg | apt-key add -
sudo su
echo "deb http://as-repository.openvpn.net/as/debian focal main">>/etc/apt/sources.list.d/openvpn-as-repo.list
exit
sudo apt update -y
sudo apt install openvpn-as -y
sudo systemctl enable openvpnas.service
sudo systemctl start openvpnas.service
```

### Creating mysql server
```
sudo fallocate -l 512M /swap
sudo chmod 600 /swap
sudo mkswap /swap
sudo swapon /swap
sudo cp /etc/fstab /etc/fstab.bak
echo '/swap none swap sw 0 0' | sudo tee -a /etc/fstab
sudo apt install vim
sudo apt install mysql-server-8.0
sudo mysql -u root
CREATE USER 'appuser'@'localhost' IDENTIFIED BY '<PASSWORD>';
```
