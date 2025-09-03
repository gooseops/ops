output "hostname" {
  value = cloudflare_dns_record.dns_record.name
}
