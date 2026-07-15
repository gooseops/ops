# CLAUDE.md

This file provides guidance to Claude Code when working in the ops repository.

## Project

**GooseOps ops** — infrastructure-as-code for the maintainer's homelab
(self-hosted services on Proxmox) plus reusable Terraform modules and
Kubernetes/Helm assets used on client engagements (AWS, GCP, Cloudflare).

Homelab services are deployed via Ansible roles/playbooks in `ansible/`
(Nextcloud, Postgres, Synapse, Jitsi, LiveKit, Vaultwarden, Grafana,
Pi-hole, WireGuard, Penpot, Jellyfin, and others — see `just playbook-list`).
VM provisioning is Proxmox via Terraform — deliberately Terraform, not
OpenTofu (unlike hivecraft-infra): this is a public portfolio repo and
keeping Terraform on it matters for résumé/skill visibility, and there's
no license-risk pressure to move off it for homelab/non-competing use.
An eventual move to Incus is planned but not yet underway (see the
maintainer's hivecraft-infra repo for that pattern already in production).

**Status (2026-07-15):** see **[PLAN.md](./PLAN.md)** for current
initiatives, the tech-debt list, and open questions — this repo tracks
ongoing infra work rather than phased product delivery. Update it at
the end of every session.

See **[explanations/INDEX.md](./explanations/INDEX.md)** for the session
changelog.

**Starting a new session:** when the user says "let's continue" or
similar, immediately read PLAN.md and the most recent file in
`explanations/` before responding or taking any action.

Two directories here are symlinks into a single separate, non-public
repo (`homecloud-infra`), kept out of this public repo on purpose:

- `ansible/inventory` → `~/github/homecloud-infra/ansible/inventory`
  (flat IP-based inventory, group_vars, host_vars)
- `terraform/worlds` → `~/github/homecloud-infra/worlds` (the whole
  worlds directory is linked as one unit, not per-world, so a future
  staging/development world shows up automatically — currently
  contains `production/`, the live Proxmox/GCP/Cloudflare state)

`homecloud-infra` was consolidated from two formerly-separate repos
(`terraform-worlds` and an un-versioned `homelab_ansible_inventory`
directory) and its single Terraform world was renamed from `world-01`
to `production` in the process. `just link-externals` (re)creates both
symlinks; the maintainer runs all git commands themselves, so don't run
git commands in `homecloud-infra` unprompted.

---

## Explanation Workflow

At the end of every session, create a new file in `explanations/` and add it
to `explanations/INDEX.md`.

**File naming:** `NNN-YYYY-MM-DD-slug.md`

**Sections:** Overview → Why This Exists → Technical Decisions → Dependencies → How It Fits Together → Gotchas → What's Next

**TTS writing rules — strictly follow these:**

- No code blocks, no inline backtick formatting
- No raw file paths — say "the justfile" not the path
- No raw URLs
- Spell out package names as spoken words ("Terraform", "Ansible", "Doppler")
- Active voice, complete sentences, flowing paragraphs — write as if narrating
- Acronyms spelled out on first use

These rules apply ONLY to files in `explanations/`. Other documentation
(READMEs, runbooks) can use code blocks, paths, and URLs as normal.

**Also at the end of every session:** offer a one-line commit message
summarizing the session's changes — do not run git commands yourself;
the maintainer runs all git commands.

---

## Tooling

**Entry point:** `nix develop`. The flake at the repo root pins the
operator-side tools: Terraform, tflint, Ansible + ansible-lint, Doppler,
just, jq, shellcheck, python3, awscli2, google-cloud-sdk. Anyone with Nix
installed can run any operator command in the repo without separately
installing anything.

**Daily commands** are wrapped in the `justfile`. `just --list` shows the
menu. The justfile composes `doppler run --command '...'` around every
command that needs secrets, so the operator never types that incantation
by hand.

| Tool | Used for | Notes |
|---|---|---|
| Terraform | Cloud + Proxmox resources | Modules under `terraform/modules/`, composed per-world under `terraform/worlds/<world>/`. |
| Proxmox | Homelab hypervisor | Via the `terraform/modules/proxmox/qemu-vm` module. Incus is a planned future migration, not current state — do not assume Incus tooling/conventions apply here yet. |
| Ansible | Host config | Playbooks at the root of `ansible/`, roles under `ansible/roles/<role>/`. |
| Doppler | Secrets injection | `doppler run --command '...'` wraps every play/apply that needs a secret, enforced via the justfile. Doppler project: `ops`. |
| just | Command runner | Single source of truth for operator-facing commands; recipes wrap doppler + cd + playbook-name conventions. |
| Nix flake | Pinned dev shell | `nix develop` puts the whole toolchain on PATH. |

The justfile's IaC recipes are named `tf-*` (`tf-init`, `tf-plan`,
`tf-apply`, ...), not `tofu-*` — deliberately tool-agnostic naming, even
though this repo's flake pins the actual `terraform` binary (see above).
Don't rename these to `tofu-*` or add a `tofu` alias.

Env-sourced values (Doppler-injected secrets, DB credentials, anything
via `lookup('ansible.builtin.env', ...)`) live in
`ansible/inventory/group_vars/<group>.yml`, not in role `defaults/` —
see e.g. `group_vars/postgresql.yml`. Role `defaults/` are for
role-internal, cluster-agnostic defaults only (versions, paths, timeouts).

**`lookup('env', ...)` never appears inside a role's `tasks/`.** The env
lookup itself always lives in group_vars/host_vars, bound to a plain,
role-prefixed variable (e.g. `base_admin_pubkey`). `defaults/main.yml`
declares that variable too, but with an empty string or a genuinely
meaningful static default — never the lookup itself; an empty default
is not a real default, it's a placeholder that a task-level assertion
checks and fails loud on if group_vars didn't actually supply a value.
Tasks reference only the plain variable, never `lookup('env', ...)`
directly. See `ansible/roles/base/` (`defaults/main.yml` +
`group_vars/all.yml`'s `base_admin_pubkey`) for the pattern.

---

## Working Style

- Be concise, even at the expense of having bad grammar or manners.
- Make direct technical recommendations; do not present option lists for trivial decisions.
- The maintainer is a DevOps engineer running this themselves — assume infrastructure competency.
- Provide commands for the maintainer to run; do not execute Ansible/Terraform deploys or applies via Bash — read-only checks (lint, inventory listing, plan/dry-run) are fine to run directly.
- Push back when warranted.
- Ask clarifying questions when scope is unclear, especially before guessing at secret names, environment names, or paths into the symlinked external repos.

---

## Secrets

NEVER commit:

- Terraform state files
- Ansible vault passwords
- WireGuard private keys
- TLS private keys
- Cloud provider API tokens
- SSH private keys

Doppler is the secrets manager. `.envs/` and `.keys/` (populated by
`just setup`/`just use`) are gitignored and never committed.

---

## Conventions

### Ansible directory layout

- Playbooks live at the root of `ansible/` (e.g. `ansible/base.playbook.yml`), NOT under a `playbooks/` subdirectory.
- Roles live in `ansible/roles/<role-name>/` with the standard `tasks/`, `handlers/`, `defaults/`, `files/`, `templates/`, `vars/` layout.
- Inventory is a single flat `homelab.ini` (symlinked in from `homecloud-infra`), grouped by service name (e.g. `nextcloud`, `penpot`, `wireguard`) rather than by environment — there is currently one environment (`prod`), not the multi-environment layout hivecraft-infra uses.
- No `ansible.cfg` (matches hivecraft-infra exactly — removed on purpose,
  don't reintroduce one). Instead: `ansible_user` and
  `ansible_ssh_private_key_file` are set in
  `ansible/inventory/group_vars/all.yml` via `lookup('env', ...)` —
  `ANSIBLE_USER` comes from Doppler (injected by `doppler run`),
  the key path resolves to `.keys/${DOPPLER_CONFIG}` at play time. Every
  `ansible-inventory`/`ansible-playbook`/`ansible` invocation passes
  `-i inventory/homelab.ini` explicitly instead of relying on an
  ansible.cfg default. `ANSIBLE_HOST_KEY_CHECKING=False` is set in
  `.envs/.env.<env>` (by `f_setupEnv`) rather than a global ansible.cfg
  setting — deliberately kept (unlike hivecraft-infra, which doesn't
  blanket-disable it) because homelab VMs get rebuilt/reinstalled often
  enough that host key churn would otherwise block every redeploy.

### `just` vs Ansible boundary

`just` is a command runner that executes on the operator's devbox.
Recipes may only invoke tools that are installed locally (or pinned in
`nix develop`) — never tools that only exist on cluster hosts. Anything
that needs to run *on* a host goes through an Ansible role + playbook
invoked via `ansible-playbook`. The `just ssh <group>` recipe is the one
exception: it's an interactive login convenience, not a way to run
commands remotely — ad-hoc remote commands still go through Ansible
(`ansible -m shell ...`), not a `just` recipe shelling out over `ssh`.

### Keeping inventory/worlds out of the public repo

Both `ansible/inventory` and `terraform/worlds` are deliberately symlinks
to directories inside `homecloud-infra`, outside this repo, so host IPs,
group_vars, and live Terraform state never land in the public ops repo.
`homecloud-infra` is its own git repo (its own history, backend config,
`.gitignore` for `.terraform/`/state) covering both the inventory and
every Terraform world. `terraform/worlds` links the whole worlds
directory rather than one world at a time, so adding a staging or
development world later needs no justfile change — it just appears
under `terraform/worlds/<name>`.

---

## What goes where

| Concern | Lives in |
|---|---|
| Homelab service config (Ansible) | `ansible/roles/<service>/` + `ansible/<service>.playbook.yml` |
| Admin-user bootstrap + SSH hardening (every host) | `ansible/roles/base/`, applied via `base.playbook.yml`'s `roles:` list |
| Inventory (symlinked, external repo) | `ansible/inventory` → `~/github/homecloud-infra/ansible/inventory` |
| Reusable Terraform building blocks | `terraform/modules/<module-name>/` |
| Live Terraform state/config (symlinked, external repo) | `terraform/worlds` → `~/github/homecloud-infra/worlds/` (currently just `production/`) |
| Kubernetes manifests (client work) | `kubernetes/manifests/` |
| Helm values/charts (client work) | `helm/` |
| One-off operator scripts | `scripts/` (personal/media scripts live under `scripts/personal_use/`, unrelated to infra ops — not linted by `just lint`) |
| Session-by-session changelog | `explanations/` |
