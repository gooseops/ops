
module "nextcloud" {
  providers = {
    proxmox = proxmox.proxmox-01
  }
  source = "../../../modules/proxmox/qemu-vm/3.0.1-rc1"

  ciuser  = "administrator"
  sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

  config = {
    name        = "nextcloud"
    desc        = <<-EOT
            Nextcloud Hub is the industry-leading, fully open-source,
            on premise content collaboration platform. Teams access, 
            share and edit their documents, chat and participate in 
            video calls and manage their mail and calendar and projects 
            across mobile, desktop and web interfaces.
        EOT
    vmid        = "101"
    target_node = "proxmox-01"
    clone       = "ubuntu-noble-amd64"
    cores       = 4
    memory      = 8192
    sockets     = 1
    agent       = 1
    onboot      = true

    disk = {
      backup  = false
      storage = "local-zfs-sdb"
      size    = 100
      ssd     = true
    }

    network = {
      bridge   = "vmbr0"
      firewall = true
      model    = "virtio"
    }
  }
}

module "nextcloud_tunnel" {
  source = "../../../modules/cloudflare/cloudflare-tunnel/2.0.0"

  cloudflare_account_id = data.doppler_secrets.prod_secrets.map.CLOUDFLARE_ACCOUNT_ID
  tunnel_name           = "nc-gooseops-com"
}

module "nextcloud_dns_record" {
  source = "../../../modules/cloudflare/record/1.0.0"

  name    = "nc"
  type    = "CNAME"
  zone_id = data.doppler_secrets.prod_secrets.map.CLOUDFLARE_GOOSEOPS_COM_ZONE_ID
  content = "${module.nextcloud_tunnel.tunnel_map.id}.cfargotunnel.com"
}

module "nc_tunnel_account" {
  source = "../../../modules/doppler/secret/1.0.0"

  doppler_project = data.doppler_secrets.prod_secrets.project
  doppler_config  = data.doppler_secrets.prod_secrets.config
  secret_name     = "NC_TUNNEL_ACCOUNT"
  secret_value    = module.nextcloud_tunnel.tunnel_map.account_tag
}

module "nc_tunnel_id" {
  source = "../../../modules/doppler/secret/1.0.0"

  doppler_project = data.doppler_secrets.prod_secrets.project
  doppler_config  = data.doppler_secrets.prod_secrets.config
  secret_name     = "NC_TUNNEL_ID"
  secret_value    = module.nextcloud_tunnel.tunnel_map.id
}

module "nc_tunnel_name" {
  source = "../../../modules/doppler/secret/1.0.0"

  doppler_project = data.doppler_secrets.prod_secrets.project
  doppler_config  = data.doppler_secrets.prod_secrets.config
  secret_name     = "NC_TUNNEL_NAME"
  secret_value    = module.nextcloud_tunnel.tunnel_map.name
}

module "nc_tunnel_secret" {
  source = "../../../modules/doppler/secret/1.0.0"

  doppler_project = data.doppler_secrets.prod_secrets.project
  doppler_config  = data.doppler_secrets.prod_secrets.config
  secret_name     = "NC_TUNNEL_SECRET"
  secret_value    = module.nextcloud_tunnel.tunnel_map.tunnel_secret
}

module "nc_tunnel_hostname" {
  source = "../../../modules/doppler/secret/1.0.0"

  doppler_project = data.doppler_secrets.prod_secrets.project
  doppler_config  = data.doppler_secrets.prod_secrets.config
  secret_name     = "NC_TUNNEL_HOSTNAME"
  secret_value    = "${module.nextcloud_dns_record.dns_record.name}.${data.cloudflare_zone.gooseops.name}"
}
