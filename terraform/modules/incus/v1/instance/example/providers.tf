terraform {
  required_version = "~> 1.10"
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 1.1"
    }
  }
}

provider "incus" {
  # Defaults to the local Incus client config at ~/.config/incus/.
  # Override via remote = "..." or by setting environment variables
  # (INCUS_REMOTE, INCUS_SOCKET) at apply time.
}
