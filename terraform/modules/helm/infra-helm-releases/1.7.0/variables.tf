
variable "ctx_doppler_project" {
    type        = string
    default     = "deltacm"
    description = "This is always deltacm"
}

variable "ctx_doppler_config" {
    type = string
}

variable "ctx_doppler_config_dns_safe" {
    type = string
    description = "This value usually comes from doppler and is safe for dns names"
}

variable "deltacm_home" {
    type = string
}

variable "k8s_cluster_version" {
    type = string
}

variable "namespace" {
    type        = string
    default     = null
    description = "The optional namespace for helmcharts to be deployed to"
}

## doppler operator helm release configuration variables
variable "is_doppler_operator_enabled" {
    type    = bool
    default = false
}

## gitlab-agent helm release configuration variables
variable "is_gitlab_cluster_agent_enabled" {
    type    = bool
    default = false
}

variable "gitlab_agent_token" {
    type    = string
    default = null
}

## datadog helm release configuration variables
variable "is_datadog_enabled" {
    type    = bool
    default = false
}

variable "cluster_name" {
    type    = string
    default = null
}

variable "datadog_api_key" {
    type    = string
    default = null
}

variable "datadog_app_key" {
    type    = string
    default = null
}

variable "datadog_log_collection" {
    type    = string
    default = false
}

## cloudflare-tunnel helm release configuration variables
variable "is_cloudflare_tunnel_enabled" {
    type    = bool
    default = false
}

variable "cloudflare_tunnels" {
    type    = object({
        account_id   = string,
        cname        = string,
        id           = string,
        name         = string,
        secret       = string,
        tunnel_token = string
    })
    default = null
    description =<<EOF
    This map is typically defined by the outputs of other modules and does not need to be set
    manually.
    EOF
}

variable "domains" {
    type    = list(string)
    default = null
    description =<<EOF
    A list of domains that will eventually be passed into the cloudflared 
    config.yml ingress block
    EOF
}

## gitlab-runner helm release configuration variables
variable "is_gitlab_runner_enabled" {
    type    = bool
    default = false
}

variable "gitlab_runner_authentication_token" {
    type    = string
    default = null
}

variable "gitlab_runner_name" {
    type    = string
    default = "null"
}

## kube-metrics helm release configuration variables
variable "is_metrics_server_enabled" {
    type    = bool
    default = false
}

## traefik helm release configuration variables
variable "is_traefik_enabled" {
    type    = bool
    default = false
}

## delta-network-chart helm release configuration variables
variable "is_delta_network_chart_enabled" {
    type    = bool
    default = false
}
variable "delta_network_chart_namespace" {
    type    = string
    default = null
}

## metabase helm release configuration variables
variable "is_metabase_enabled" {
    type    = bool
    default = false
}

variable "metabase_chart_version" {
    type = string
    description = "Version of the metabase helm chart to use for deploying metabase."
    default = "1.0.1"
}

variable "ctx_deltacm_read_api_token" {
    type = string
    description = "Token used to pull packages repo associated with deltacm"
    default = null
}

variable "mb_db_type" {
    type    = string
    default = null
}

variable "mb_db_dbname" {
    type    = string
    default = null
}

variable "mb_db_port" {
    type    = string
    default = null
}

variable "mb_db_user" {
    type    = string
    default = null
}

variable "mb_db_pass" {
    type    = string
    default = null
}

variable "mb_db_host" {
    type    = string
    default = null
}