output "name" {
  description = "Incus instance name."
  value       = incus_instance.this.name
}

output "fqdn" {
  description = "FQDN written into the guest at first boot."
  value       = var.fqdn
}

output "ipv4_address" {
  description = "Static IPv4 address assigned inside the guest."
  value       = var.ipv4_address
}

output "cluster_target" {
  description = "Incus cluster member the instance was placed on."
  value       = incus_instance.this.target
}
