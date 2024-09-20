
resource "tls_cert_request" "request" {
  private_key_pem = var.prvkey

  subject {
    common_name  = var.common_name
    organization = var.organization
  }

  dns_names    = var.hostnames
  ip_addresses = var.ip_addresses

}

resource "cloudflare_origin_ca_certificate" "ca_certificate" {
  hostnames          = var.hostnames
  requested_validity = var.requested_validity
  csr                = tls_cert_request.request.cert_request_pem
  request_type       = var.request_type
}
