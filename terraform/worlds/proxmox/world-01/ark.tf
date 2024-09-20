
module "ark" {
  providers = {
    proxmox = proxmox.proxmox-01
  }
  source = "../../../modules/proxmox/qemu-vm/3.0.1-rc1"

  ciuser  = "administrator"
  sshkeys = data.doppler_secrets.prod_secrets.map.HOMELAB_PUB_KEY

  config = {
    name        = "ark"
    desc        = <<-EOT
            RESPAWN INTO A NEW DINOSAUR SURVIVAL EXPERIENCE BEYOND YOUR WILDEST DREAMS… 
            AS ARK IS REIMAGINED FROM THE GROUND-UP INTO THE NEXT-GENERATION OF 
            VIDEOGAME TECHNOLOGY WITH UNREAL ENGINE 5! YOU AWAKE ON A MYSTERIOUS ISLAND, 
            YOUR SENSES OVERWHELMED BY THE BLINDING SUNLIGHT AND BRILLIANT COLORS BOUNCING 
            OFF EVERY SURFACE AROUND YOU, THE AZURE WATERS OF A VERDANT ISLAND LAPPING AT 
            YOUR BARE FEET. A DEEP ROAR ECHOES FROM THE MISTY JUNGLE, JOLTING YOU INTO 
            ACTION, AND YOU STAND UP – NOT AFRAID, BUT INTRIGUED. ARE YOU READY TO FORM A 
            TRIBE, TAME AND BREED HUNDREDS OF SPECIES OF DINOSAURS AND OTHER PRIMEVAL 
            CREATURES, EXPLORE, CRAFT, BUILD, AND FIGHT YOUR WAY TO THE TOP OF THE 
            FOOD-CHAIN? YOUR NEW WORLD AWAITS… STEP THROUGH THE LOOKING-GLASS AND JOIN IT!
        EOT
    vmid        = "101"
    target_node = "proxmox-01"
    clone       = "ubuntu-noble-amd64"
    cores       = 2
    memory      = 12288
    sockets     = 1
    agent       = 1
    onboot      = true

    disk = {
      backup  = false
      storage = "local-lvm"
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
