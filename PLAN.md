# Ops Plan

## Project Name

**GooseOps ops**

---

## What This Repo Is

Infrastructure-as-code for the maintainer's homelab (self-hosted services
on Proxmox) plus reusable Terraform modules and Kubernetes/Helm assets
used on client engagements (AWS, GCP, Cloudflare). Not a single product
with a roadmap toward a launch — this plan tracks ongoing infra
initiatives and tech debt rather than phased feature delivery.

---

## Status — 2026-07-15

- This session: justfile and tooling brought in line with the
  maintainer's hivecraft-infra conventions — Doppler-backed
  `just setup`/`just use` env flow, `jq`/`shellcheck` added to the Nix
  flake, `ansible/requirements.yml` added (four Galaxy collections the
  roles already depended on with no declarative install path), and
  `CLAUDE.md` created.
- Active branch: `feat/odoo_role` — adding Odoo. A Proxmox VM and a
  Postgres user/db were created manually; the Ansible role/playbook
  have not been written yet. Manual install walkthrough hit an
  unresolved apt dependency chain on `wkhtmltox`
  (fontconfig/libjpeg62-turbo/libx11-6/libxcb1/libxext6/libxrender1/
  xfonts-75dpi/xfonts-base not installable as of last attempt).
- **Known caveat:** `ansible/*.playbook.yml` and the `homelab.ini`
  inventory (symlinked from `homecloud-infra`) contain a mix
  of live, decommissioned, and needs-touchup entries that have not been
  reconciled against what's actually running. Everything below under
  Topology/Services is "what's declared in the repo," not confirmed
  live state — see the audit item under Next Up.
- The formerly-separate `terraform-worlds` repo and the un-versioned
  `homelab_ansible_inventory` directory have been consolidated into one
  private repo, `homecloud-infra` (`~/github/homecloud-infra`), with
  `ansible/inventory/` and `worlds/` as its two top-level dirs. The
  single Terraform world was renamed `world-01` → `production` in the
  process. `ops`'s `terraform/worlds` and `ansible/inventory` symlinks
  now point into it; `terraform/worlds` links the whole worlds
  directory rather than one world at a time so a future staging/dev
  world needs no justfile change.

---

## Topology Summary (as declared — unaudited)

- Proxmox: two API targets configured in Terraform (default provider +
  a `proxmox-01` alias — see `terraform/worlds/production/providers.tf`).
- LAN VMs: `192.168.1.100–113` and `192.168.1.200–207` (`local_vms` group).
- Cloud: one GCP VM (`34.23.34.81`) — `cloud_proxy`, also in the
  `wireguard` group as the tunnel's cloud-side edge.
- One environment today: Doppler config `prod` (project `ops`).

---

## Services (declared in homelab.ini / ansible/roles — needs audit)

| Group | Playbook/Role | Notes |
|---|---|---|
| nextcloud | `nextcloud` | |
| penpot | `penpot` | |
| ai_studio | `ai-studio` (open-webui + invokeai, NVIDIA container runtime) | Cloudflare Tunnel fronted |
| llm | (overlaps ai_studio host + a second host) | |
| openclaw | — | No Ansible role; managed via manual shell commands per local notes |
| jitsi | `jitsi` | |
| livekit | `livekit` | |
| postgresql | `postgresql` | Shared DB host; per-app db/user config lives in `group_vars/postgresql.yml` via env lookups (synapse, vaultwarden, mattermost, odoo, ...) |
| synapse | `synapse` | Matrix homeserver |
| coturn | `coturn` | TURN server |
| omada | `omada-software-controller` | |
| pihole | `pihole` | |
| wireguard | `wireguard` | Tunnel mesh incl. the cloud_proxy edge |
| vaultwarden | `vaultwarden` | |
| grafana | `grafana` | |
| gooseops_fe | `gooseops-fe` | |
| jellyfin | `jellyfin` | |
| hivecraft_web | `hivecraft-web` | |
| bigbox (`192.168.1.100`) | no dedicated playbook/group_vars found | Purpose unclear from repo alone — needs audit |
| *(no matching inventory group)* | `drosera-operator`, `reth`, `lighthouse`, `hugo` playbooks/roles exist | `reth`+`lighthouse` look like an Ethereum execution/consensus client pair; not obviously wired to a `homelab.ini` group — needs audit |
| — | `ansible/roles/mattermost` | Role exists with no corresponding `*.playbook.yml` — dead or incomplete |

---

## Tech Stack

- **Terraform** (deliberately, not OpenTofu — résumé/skill visibility
  on this public repo, and no license-risk pressure for homelab/
  non-competing use; hivecraft-infra uses OpenTofu instead) + Proxmox
  via the Telmate provider, plus Cloudflare/GCP/AWS modules for client
  work. Justfile recipes are named `tf-*`, not `tofu-*`, on purpose.
- **Ansible**: `community.general`, `community.docker`,
  `community.postgresql`, `ansible.posix`.
- **Doppler** for all secrets (project `ops`, config `prod`).
- **Nix flake + just** for operator tooling.

---

## Initiatives

- **Operator tooling & workflow alignment** (this session) — DONE.
  Justfile parity with hivecraft-infra's setup/lint/deploy/ssh
  conventions; CLAUDE.md; `ansible/requirements.yml`; flake additions
  incl. a shellHook (sources `.envs/.env` into the bare `nix develop`
  prompt, `reload-env` helper — matches hivecraft-infra).
- **SSH key/user unification** — DONE. Removed `ansible.cfg` entirely
  (both the `ops/ansible/ansible.cfg` symlink and the real file in
  `homecloud-infra`), matching hivecraft-infra exactly. `ansible_user`
  and `ansible_ssh_private_key_file` now live in
  `ansible/inventory/group_vars/all.yml` via `lookup('env', ...)`, so
  `ansible-playbook` and `just ssh` both authenticate with the same
  Doppler-sourced `.keys/${DOPPLER_CONFIG}` key and `ANSIBLE_USER` —
  no more silent divergence between the two. Every
  `ansible-inventory`/`ansible-playbook`/`ansible` call in the justfile
  now passes `-i inventory/homelab.ini` explicitly. `ANSIBLE_USER`,
  `ANSIBLE_SSH_PRVKEY`, and `ANSIBLE_SSH_PUBKEY` are now set as Doppler
  secrets in the `ops`/`prod` config — verified live via
  `--connection=local -m debug`. `ANSIBLE_HOST_KEY_CHECKING=False` relocated from
  ansible.cfg into `.envs/.env.<env>` (kept, unlike hivecraft-infra,
  because homelab VMs get rebuilt often enough that host key churn
  would otherwise block every redeploy).
- **`base` role: admin-user bootstrap + SSH hardening** — DONE. New
  `ansible/roles/base/` mirrors hivecraft-infra's admin-user layer:
  ensures the admin user exists, installs its authorized_keys, drops a
  NOPASSWD sudoers entry, locks the account's password (key-only auth),
  then hardens sshd — same careful ordering as hivecraft-infra (SSH
  hardening last, since it's the layer that locks you out if anything
  upstream broke key-based auth). One deliberate divergence: the admin
  pubkey comes from `base_admin_pubkey` (empty placeholder in
  `defaults/main.yml`, sourced for real via `lookup('env',
  'ANSIBLE_SSH_PUBKEY')` in `group_vars/all.yml`) rather than a static
  committed `files/authorized_keys` file, since Doppler is already the
  source of truth for that key here — first pass wrongly put the
  `lookup('env', ...)` directly in `tasks/main.yml`; corrected to route
  through `defaults/` + `group_vars` like every other env-sourced value,
  per the convention in CLAUDE.md (env lookups never appear in tasks).
  Scoped narrower than hivecraft-infra's `base` role — doesn't cover
  hostname/timezone/locale/chrony/journald/unattended-upgrades; add
  those later if wanted. Wired into `base.playbook.yml`'s `roles:` list
  ahead of `node-exporter`. Verified via syntax-check + `ansible-lint`
  (passes at the `production` profile) and a live
  `--connection=local -m debug` check that `ansible_user`/
  `base_admin_pubkey` resolve correctly through `doppler run` — not yet
  applied to any real host.
- **`noop` connectivity-check playbook** — DONE. Pulled over from
  hivecraft-infra verbatim (fully generic — no FQDN/hostname
  assumptions): reports `inventory_hostname`, `ansible_host`,
  `ansible_user`, and OS facts per host, makes no changes. `check` /
  `deploy` / `deploy-bootstrap` default `playbook=` switched from
  `"base"` to `"noop"` to match — now that `base` actually mutates
  admin-user/SSH config, defaulting to it against `host="all"` with no
  playbook argument was a real footgun; `noop` is the safe default,
  same as hivecraft-infra.
- **Local dev/workflow follow-ups** — PROPOSED, deferred for a focused
  session. Two items, not yet scheduled:
  - Add a scoped `.ansible-lint` config (profile + targeted rule
    exclusions) so `just lint` passes cleanly against current reality
    instead of always failing on the ~52 pre-existing findings —
    without pretending the underlying debt is fixed.
  - `deploy`/`check` default to `host="all"`, which — combined with the
    inventory audit still being unaudited — means a fat-fingered
    `just deploy base` touches every declared host, stale or not.
    Consider requiring an explicit `host=` until the audit lands.
- **Odoo service** (branch `feat/odoo_role`) — IN PROGRESS. VM +
  Postgres db done manually; Ansible role/playbook not started; apt
  dependency chain for `wkhtmltox` unresolved.
- **Inventory/worlds consolidation** — DONE. `terraform-worlds` and
  `homelab_ansible_inventory` merged into one private repo,
  `homecloud-infra`; the Terraform world renamed `world-01` →
  `production`; `ops`'s symlinks and justfile (`default_world`,
  `link-externals`) updated to match.
- **Proxmox → Incus migration** — PLANNED, not started. hivecraft-infra
  already runs this pattern in production; ops would follow once
  scheduled.
- **Inventory/playbook audit** — PROPOSED. Reconcile declared services
  (`homelab.ini` groups + `ansible/roles`) against what's actually
  running; retire dead entries, fix the ones needing touchups.

---

## Tech Debt

- ~52 pre-existing `ansible-lint` findings across roles, surfaced by
  `just lint` this session (mostly `command-instead-of-module`,
  `var-naming[no-role-prefix]`, `risky-shell-pipe`, `package-latest`,
  `risky-file-permissions`, `no-changed-when`). Not fixed as part of
  this session's scope.
- Stale/decommissioned entries in `homelab.ini` and `ansible/roles` —
  see the audit initiative above.
- `mattermost` role has no corresponding playbook.
- `openclaw` is managed via manual shell commands, not an Ansible role.
- `.envs`/`.keys` setup (`just setup`/`use`) pulls the SSH key pair
  only; a GCP service-account key and/or kubeconfig pull (like
  hivecraft-infra's) were deliberately deferred until their Doppler
  secret names are confirmed.
- Odoo's `wkhtmltox` apt dependency chain is unresolved.

---

## Open Questions

- Which `homelab.ini` groups/playbooks are actually live vs
  decommissioned vs needing touchups?
- Timeline/trigger for the Proxmox → Incus migration.
- Whether/when a second Doppler environment gets added (single `prod`
  today).
- Whether/when a `staging` or `development` world gets added under
  `homecloud-infra/worlds/` (the symlink + justfile already support it
  with no further change).

---

## Next Up

1. Finish the Odoo Ansible role (resolve `wkhtmltox` deps, codify the
   manual VM/Postgres setup into the role/playbook).
2. Reconcile `homelab.ini` + `ansible/roles` against live infra (the
   audit above) so this plan's Services table can drop its caveat.
