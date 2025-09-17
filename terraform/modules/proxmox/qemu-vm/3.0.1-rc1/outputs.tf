output "vm" {
  value = proxmox_vm_qemu.proxmox-vm
}

output "vm_ip" {
  value = proxmox_vm_qemu.proxmox-vm.default_ipv4_address
}
