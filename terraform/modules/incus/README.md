# Incus Modules

Terraform modules for Incus resources, targeting the [`lxc/incus`](https://registry.terraform.io/providers/lxc/incus/latest)
provider. Two submodules under `1.1/` (the provider minor version they're
built against, matching this repo's `terraform/modules/proxmox/qemu-vm/`
versioning convention):

- `1.1/instance/` — a single Incus instance (VM or container): config,
  root disk, and one bridged NIC, provisioned via cloud-init.
- `1.1/profile/` — a single Incus profile: config + device overrides,
  attachable to instances in addition to the cluster's `default` profile.

## Design notes

- `instance`'s `image` variable is **required, no default**. Unlike a
  greenfield single-consumer setup, this is public boilerplate — there's
  no one "right" pinned image alias to bake in. Pin your own local image
  (see `ansible/roles/incus-image-pin` for the pattern: copy an upstream
  image into the local Incus image store under an alias you control,
  `--auto-update=false` so it doesn't silently drift) and pass that alias
  in.
- `instance`'s cloud-init template installs `openssh-server` and writes a
  deliberate `sshd_config` — this works around a real bug in the
  `images:debian/13/cloud` upstream image (it strips the SSH server and
  replaces `sshd_config` with a single `PasswordAuthentication no` line,
  losing `UsePAM yes`; combined with the template's `lock_passwd: true`
  admin user, that leaves sshd rejecting every login, even valid pubkey
  auth). Harmless if you're pinning a different upstream image that
  doesn't have this bug — the fix is idempotent.
- Cluster placement (`cluster_target`) and storage pool (`storage_pool`)
  are both required, no defaults — this module doesn't assume you're
  running a cluster of any particular size or a pool named any particular
  thing.

See each submodule's `example/` directory for illustrative (non-live)
usage.
