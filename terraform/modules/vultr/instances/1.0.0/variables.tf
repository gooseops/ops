variable "plan" {
  type        = string
  description = "Plan of the instance"
}
variable "region" {
  type        = string
  description = "Region to deploy the instance"
}
variable "os_id" {
  type        = number
  description = "OS ID of the instance"
}

variable "label" {
  type        = string
  description = "Label of the instance"
}

variable "hostname" {
  type        = string
  description = "Hostname of the instance"
}
