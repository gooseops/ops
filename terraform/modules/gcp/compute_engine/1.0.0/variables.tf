variable "project" {
  type        = string
  default     = null
  description = "Override provider project."
}

variable "name" {
  type        = string
  description = "Name of the resources to be added"
}

variable "machine_type" {
  type        = string
  default     = "e2-micro"
  description = <<EOF
    Resource/Machine size of node
    Format: "NAME" from the results of command 
    `gcloud compute machine-types list | less`
    EOF 
}

variable "zone" {
  type        = string
  default     = "europe-southwest1-a"
  description = "The region zone that this node will be located in"
}

variable "tags" {
  type        = list(string)
  default     = ["node"]
  description = <<EOF
    List of tags that will be added to the node 
    Useful for using ansible dynamic inventories
    EOF
}

variable "allow_stopping_for_update" {
  type    = bool
  default = true
}

variable "enable_oslogin" {
  type        = string
  default     = "TRUE"
  description = "Whether or not to enable OS login with"
}

variable "compute_image" {
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
  description = <<EOF
    OS Image to use for the node
    Format: "PROJECT/FAMILY" from the results of command 
    `gcloud compute images list`
    EOF
}

variable "boot_disk_size" {
  type        = number
  default     = null
  description = "Size of the vm bootdsisk"
}

variable "boot_disk_type" {
  type    = string
  default = "pd-standard"
}

variable "network" {
  type        = string
  default     = "default"
  description = "The name of the VPC network to join"
}

variable "admin_user" {
  type        = string
  description = "Username of the administrative vm user"
}

variable "admin_pubkey" {
  type        = string
  description = "Public key of the administrative vm user"
}
