variable "algorithm" {
  type        = string
  default     = "ED25519"
  description = "Name of the algorithm to use when generating the private key. Currently-supported values are: RSA, ECDSA, ED25519."
}

variable "ecdsa_curve" {
  type        = string
  default     = null
  description = "When algorithm is ECDSA, the name of the elliptic curve to use. Currently-supported values are: P224, P256, P384, P521. (default: P224)."
}

variable "rsa_bits" {
  type        = number
  default     = null
  description = "When algorithm is RSA, the size of the generated RSA key, in bits (default: 2048)."
}
