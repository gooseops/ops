
# resource "tls_cert_request" "request" {
#   private_key_pem = var.prvkey

#   subject {
#     common_name  = var.common_name
#     organization = var.organization
#   }

#   dns_names = var.hostnames
#   ip_addresses = var.ip_addresses

# }

resource "tls_self_signed_cert" "cert" {
  private_key_pem = var.prvkey

  subject {
    common_name  = var.common_name
    organization = var.organization
  }

  set_authority_key_id = var.set_authority_key_id
  set_subject_key_id   = var.set_subject_key_id

  is_ca_certificate = var.is_ca_certificate
  dns_names         = var.hostnames
  ip_addresses      = var.ip_addresses

  validity_period_hours = var.validity_period_hours

  allowed_uses = var.allowed_uses
}
