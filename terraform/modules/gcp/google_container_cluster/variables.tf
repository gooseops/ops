
## Service account information
variable "service_account_id" {
    type = string
}

variable "service_account_display_name" {
    type = string
    default = null
}

variable "service_account_is_disabled" {
    type = bool
    default = false
}


## GKE Container Cluster information
variable "gke_cluster_name" {
    type = string
}

variable "location" {
    type = string
}

variable "deletion_protection" {
    type = bool
    default = false
}

variable "remove_default_node_pool" {
    type = bool
}

variable "initial_node_count" {
    type = number
    default = 1
}

## Nodepool Information
variable "node_pool_name" {
    type = string
}

variable "node_count" {
    type = number
}

variable "preemptible" {
    type = bool
}

variable "machine_type" {
    type = string
}