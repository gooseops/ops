
# ECDSA key with P384 elliptic curve
resource "tls_private_key" "ecdsa-p384-example" {
  algorithm   = var.algorithm
  ecdsa_curve = var.ecdsa_curve
  rsa_bits    = var.rsa_bits
}
