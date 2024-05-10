variable "doppler_project" {
    type = string
    description = "Name of Doppler Project to add Secrte to"
}

variable "doppler_config" {
    type = string
    description = "Name of Doppler Config to add Secret to"
}

variable "secret_name" {
    type = string
    description = "Name of secret. ALL_CAPS_AND_UNDERSCORES"
}

variable "secret_value" {
    type = string
    description = "Value of secret"
}