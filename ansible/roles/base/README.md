# base role

Admin-user bootstrap and SSH hardening. Applied to every host in the
inventory.

Scoped intentionally narrower than hivecraft-infra's `base` role, which
also covers hostname/timezone/locale/`/etc/hosts`/chrony/journald/
unattended-upgrades — ops doesn't have hivecraft's FQDN-per-tier scheme
for the `/etc/hosts` piece, and the rest wasn't part of the gap this
role was built to close. Add those layers here later if wanted.

## Layered build-out

1. ✅ Admin user + authorized_keys + sudoers
2. ✅ SSH hardening (`PermitRootLogin no`, `PasswordAuthentication no`)

SSH hardening runs last because it is the layer that will lock you out
if the admin-user layer broke key-based auth first.

## Conventions

- The Ansible remote user is always referenced via `{{ ansible_user }}`,
  sourced from Doppler as `ANSIBLE_USER` and bound in
  `ansible/inventory/group_vars/all.yml`.
- The admin pubkey comes from `base_admin_pubkey` (declared empty in
  `defaults/main.yml`, set for real in `ansible/inventory/group_vars/all.yml`
  via `lookup('env', 'ANSIBLE_SSH_PUBKEY')`) rather than a static
  committed `files/authorized_keys` — unlike hivecraft-infra's version
  of this role, which uses a static file. Doppler is already the single
  source of truth for this key pair in ops (see `scripts/functions.sh`),
  so sourcing it live avoids keeping the same public key in two places.
  The env lookup itself lives in group_vars, never in a task — tasks
  only ever reference `base_admin_pubkey`, and the assertion that it's
  non-empty fails loud before anything tries to use it.
- `authorized_key`'s `exclusive: true` means running this role against
  a host replaces whatever's currently in `authorized_keys` with
  exactly this key. Make sure the `ANSIBLE_SSH_PUBKEY`/`ANSIBLE_SSH_PRVKEY`
  Doppler secrets match the key already trusted on existing hosts before
  the first run, or you'll lock yourself out.
- sshd's `AllowUsers` is driven by `base_ssh_allowed_users`, defaulting
  to just `[ansible_user]` (`defaults/main.yml`). Hosts with extra local
  accounts that need SSH access override this list in group_vars/
  host_vars in `homecloud-infra` — never hardcode extra usernames into
  the template or this role, since the account list is host-specific and
  the inventory repo is where host-specific data belongs. A task-level
  assertion fails loud if the resolved list is ever empty.
