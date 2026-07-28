variable "name" {
  description = "Profile name. Referenced by instances via their profiles list."
  type        = string
}

variable "description" {
  description = "Free-form description shown in the Incus catalog."
  type        = string
  default     = ""
}

variable "config" {
  description = "Profile-level Incus config keys (e.g. limits.cpu, raw.qemu, environment.*, security.*). Merged with instance-level config at launch; instance config wins on key collisions."
  type        = map(string)
  default     = {}
}

variable "devices" {
  description = "Profile-level device overrides. Each entry needs a name, a device type (disk, nic, gpu, etc.), and a properties map. Instances inherit these unless they declare a same-named device, which wholly replaces the profile entry."
  type = list(object({
    name       = string
    type       = string
    properties = map(string)
  }))
  default = []
}

variable "project" {
  description = "Incus project the profile lives in."
  type        = string
  default     = "default"
}
