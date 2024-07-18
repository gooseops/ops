# module "vpn_cf_tunnel" {
#   source = "../../../modules/cloudflare/cloudflare-tunnel/1.0.0"

#   cloudflare_account_id = data.doppler_secrets.prod_secrets.map.CLOUDFLARE_ACCOUNT_ID
#   tunnel_name = "wireguard"

# }

# output "vpn_cf_tunnel" {
#   value = module.vpn_cf_tunnel.tunnel_map.secret
#   sensitive = true
# }