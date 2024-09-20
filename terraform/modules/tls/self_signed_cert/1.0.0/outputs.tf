
output "cert_pem" {
  value = tls_self_signed_cert.cert.cert_pem
}
