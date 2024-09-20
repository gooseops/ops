
output "cert_pem" {
  value = cloudflare_origin_ca_certificate.ca_certificate.certificate
}
