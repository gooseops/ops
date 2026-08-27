output "name" {
  description = "The created profile's name. Feed this into the instance module's profiles list."
  value       = incus_profile.this.name
}

output "project" {
  description = "Project the profile lives in."
  value       = incus_profile.this.project
}
