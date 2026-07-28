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

- This session: started planning the Proxmox→Incus migration, then
  relocated that work to `homecloud-infra` (`~/github/homecloud-infra`)
  after the maintainer flagged that this repo is meant to be public
  boilerplate — homelab-specific decisions, runbooks, and strategy don't
  belong here. `homecloud-infra` now carries its own `PLAN.md`,
  `docs/decisions/`, `docs/network.md`, `docs/runbooks/`, and
  `explanations/`, plus `gooseops_infra_plan.md` (the original
  web-chat-agent-drafted strategy doc). See that repo's `CLAUDE.md` for
  the repo-boundary rule going forward: reusable roles/modules live here
  in `ops`; anything that only makes sense with knowledge of the specific
  homelab (host names, IPs, hardware constraints, migration sequencing)
  lives in `homecloud-infra`. The one piece of that work that *does*
  belong here — porting HiveCraft's `incus-host`/`incus-image-pin`/
  `firewall` Ansible roles and its Incus Terraform module as generic,
  reusable building blocks — is tracked below under Initiatives; it just
  isn't started yet. Same pass: moved the Topology Summary section (real
  IPs, host counts) out to `homecloud-infra`'s `PLAN.md` too — it had
  the same public/private boundary problem as the rest of this session's
  work, just predating this session.
- Prior session: justfile and tooling brought in line with the
  maintainer's hivecraft-infra conventions — Doppler-backed
  `just setup`/`just use` env flow, `jq`/`shellcheck` added to the Nix
  flake, `ansible/requirements.yml` added (four Galaxy collections the
  roles already depended on with no declarative install path), and
  `CLAUDE.md` created.
- Active branch: `feat/odoo_role` — adding Odoo. A Proxmox VM and a
  Postgres user/db were created manually; the manual install walkthrough
  at that point hit an unresolved apt dependency chain on `wkhtmltox`
  (fontconfig/libjpeg62-turbo/libx11-6/libxcb1/libxext6/libxrender1/
  xfonts-75dpi/xfonts-base not installable as of that attempt). Root
  cause found and the role/playbook written this session — see the Odoo
  service initiative below.
- **Known caveat:** `ansible/*.playbook.yml` and the `homelab.ini`
  inventory (symlinked from `homecloud-infra`) contain a mix
  of live, decommissioned, and needs-touchup entries that have not been
  reconciled against what's actually running. The Services table below is
  "what's declared in the repo," not confirmed live state — see the audit
  item under Next Up. (Live topology facts — IPs, host counts — moved to
  `homecloud-infra`'s `PLAN.md`, see that repo's Status note.)
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

## Topology Summary

Moved to `homecloud-infra`'s `PLAN.md` (2026-07-15) — real IPs and host
counts are homelab-specific, not boilerplate. See that repo if you need
the current live-network facts.

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
| bigbox | no dedicated playbook/group_vars found | Purpose unclear from repo alone — needs audit; see `homecloud-infra`'s `PLAN.md` for its address |
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
- **Odoo service** (branch `feat/odoo_role`) — Ansible role/playbook
  DONE this session; the `wkhtmltox` dependency chain that blocked the
  earlier manual attempt is resolved (root cause + fix documented
  below). VM + Postgres db were created manually earlier and still need
  the role actually run against them (not done in this session — no
  live-host access). `ansible-lint` clean at the `production` profile
  (0 findings, 7 files); syntax-check clean including the multi-worker
  variant; the rendered `odoo.conf` verified as valid INI (both
  single-process and multi-worker variants) via a real INI parser, not
  just template rendering.
  - **Root cause of the earlier `wkhtmltox` failure**: not an OS-age
    problem, despite looking like one. Odoo needs wkhtmltopdf's separate
    "patched Qt" `.deb` (github.com/wkhtmltopdf/packaging), which ships
    one build per OS codename — installing a build for the *wrong*
    codename (e.g. an old bionic/focal build on a newer host, an easy
    mistake following an older guide) produces exactly the
    "fontconfig/libjpeg62-turbo/.../xfonts-base not installable" wall
    hit before. Confirmed via web search that the current patched
    0.12.6.1-3 build has working `.deb`s for Debian 12/13 and Ubuntu
    22.04/24.04 — no OS downgrade needed. The `ubuntu-noble-amd64`
    clone template already sitting in the inactive `do_later` Terraform
    draft for this VM is also Odoo's own currently-documented supported
    platform for its official package, so that OS choice was correct;
    it just needed wkhtmltopdf installed correctly alongside it.
  - The role installs prerequisite libraries before the codename-matched
    `.deb`, removes any distro-shipped unpatched `wkhtmltopdf`, and — the
    part a simpler role would skip — actually runs `wkhtmltopdf
    --version` and asserts `with patched qt` appears in the output
    before proceeding to install Odoo itself, rather than trusting a
    clean `apt` exit code. Unsupported OS codenames fail loud with a
    pointer to the packaging project's releases page instead of
    guessing. Full reasoning in the role's own README — read it before
    touching the wkhtmltopdf block again if this breaks in the future.
  - Follows this repo's shared-Postgres pattern (no local DB in the
    role) — this homelab's `ODOO_POSTGRESQL_*` group_vars entries
    already exist from the earlier manual setup; confirm they're still
    current before the first real run.
- **Jitsi + Coturn hardening** — DONE. The maintainer flagged the
  existing `jitsi` role as "confirmed working but not battle-tested"
  and never actually configured with a TURN server, and asked for it to
  be brought in line with conventions adopted this session. Turned out
  `coturn` needed more than hardening — it had real functional bugs
  that meant it never actually ran:
  - `coturn` previously wrote a Docker Compose file to disk and
    stopped. It never templated `turnserver.conf` at all (despite the
    compose file bind-mounting it), never installed/enabled the
    systemd unit meant to run the container, and that unit template
    itself referenced `docker-compose.yaml` while the file actually
    written was named `docker-compose.yml` — would have failed to
    start even if it had been installed. The shipped `turnserver.conf`
    was upstream's stock example file with two placeholder lines left
    live: an uncommented `cli-password=CHANGE_ME` and an uncommented
    `mysql-userdb=...password=CHANGE_ME` pointing at a MySQL instance
    that doesn't exist anywhere in this stack. All fixed — the role is
    now a complete, self-verifying deploy (directory → cert → compose
    → conf → systemd unit → enabled/started → asserted actually
    running via `docker_container_info`, not just "did `systemctl
    start` exit 0"). `ansible-lint` clean at the `production` profile
    (0 findings, 9 files); both `turnserver.conf` auth-mode variants
    and the NAT-mapping variant verified by direct Jinja rendering;
    the rendered Docker Compose file verified with a real `docker
    compose config` (all three bind mounts land correctly).
  - **The actual missing piece — TURN behind CGNAT — is now
    implemented**: `coturn_external_public_ip`/
    `coturn_external_private_ip` map straight to coturn's
    `external-ip=<public>/<private>` directive, which was sitting
    commented out in the stock config, never uncommented, in the
    previous version. `coturn`'s README explains why `external-ip`
    alone can't fix a *CGNAT* origin (only ordinary single-layer NAT)
    and points at hivecraft-infra's edge-router pattern (small public
    cloud VM + outbound WireGuard tunnel — the same shape as this
    homelab's own existing `cloud_proxy` GCP VM) as the robust fix,
    without prescribing which host to actually use — that's a
    homelab-topology decision, tracked as an open question in
    `homecloud-infra`, not decided here.
  - `jitsi` gained `jitsi_turn_*` vars (on by default, asserted
    non-empty) that template a small append-only block into
    `/etc/jitsi/meet/<domain>-config.js` (`config.p2p.stunServers`,
    client-side P2P TURN) and, separately, `jitsi_jvb_nat_harvester_*`
    (off by default) for when the Jitsi host itself needs a public/
    private address mapping in `jvb.conf`
    (`ice4j.harvest.mapping.static-mappings` — confirmed current
    syntax via web search, not assumed from memory). Both use
    `ansible.builtin.blockinfile` + `lookup('ansible.builtin.template',
    ...)` rather than owning/rewriting the package-generated files
    outright — **this exact pattern was tested standalone against a
    scratch file** (render → insert → idempotent no-op on re-run)
    before being trusted in the role, not just syntax-checked.
    Explicitly does NOT implement JVB-side media relay through the
    TURN server (the deeper NAT-traversal mechanism, distinct from
    client-side P2P TURN) — current config surface for that wasn't
    confirmed against a live instance, so the README says so plainly
    instead of guessing.
  - Also fixed along the way: `jitsi_keystore_pass` was hardcoded to
    the literal string `"changeme"` — now an empty placeholder +
    assert, matching this session's secrets convention everywhere
    else. Both `## TODO: make idempotent` comments addressed (certbot
    now has a `creates:` guard; `java_cert`'s own idempotent design
    documented rather than left as a stale TODO). Fixed a `Prosidy`
    typo, a doubled `Install | Install |` task name, dearmored the
    Jitsi GPG key via `get_url` + `command` instead of a piped shell
    one-liner (avoids the `risky-shell-pipe` finding the `docker` and
    `nginx-base` roles still carry as tracked tech debt), and added a
    real post-deploy check (`service_facts` + assert prosody/jicofo/
    jitsi-videobridge2 are actually `running`, not just that package
    install exited 0). `ansible-lint` clean at the `production`
    profile (0 findings, 8 files) after fixing one
    `command-instead-of-module` finding my first pass introduced
    (raw `systemctl is-active` → `service_facts`).
  - `coturn.playbook.yml` dropped `nginx-base` — nothing in the role
    ever used it (coturn's protocol isn't HTTP, and TLS issuance uses
    `certbot --standalone`, not the nginx plugin); it was dead weight
    pulled in without a functional reason.
  - **Follow-up round, same initiative**: the maintainer clarified this
    homelab's actual edge architecture (an SNI-passthrough nginx
    `stream` proxy in front of a WireGuard tunnel — already visible in
    `homecloud-infra`'s `cloud_proxy` group_vars, same pattern
    `livekit-turn.gooseops.com` already uses) and confirmed two more
    gaps to close:
    - **Jitsi secure domain** (user auth for meeting creation) — added
      `jitsi_secure_domain_enabled` (off by default) +
      `jitsi_secure_domain_moderators`. Switches Prosody's main
      VirtualHost from the package's default `"anonymous"` to
      `"internal_hashed"` (a `lineinfile` substitution — tested against
      a realistic sample of the package-generated file, only touches
      that one line), appends a `guest.<domain>` anonymous-join
      VirtualHost, requires Jicofo to authenticate room-creation
      requests, points `config.js` at the guest domain, and registers
      moderator accounts via `prosodyctl register`. Confirmed
      inter-component auth (Jicofo/JVB ↔ Prosody) needs none of this —
      the `jitsi-meet-prosody` package's own `postinst` already
      auto-generates those secrets on every install, verified against
      the package's actual source. `ansible-lint` clean at the
      `production` profile (0 findings, 11 files with secure domain +
      TURN + JVB harvester all enabled together).
    - **TURN-through-the-edge clarified, not fully solved**: the
      existing SNI-passthrough pattern covers TURN's TLS/443 path for
      free (just extend the existing `map $ssl_preread_server_name`
      table). The UDP relay port range doesn't fit that mechanism —
      `ssl_preread` needs a TLS ClientHello over TCP, there's no UDP
      equivalent — and proxying a wide port range through nginx has
      real problems beyond just being tedious to configure (per-port
      listener overhead, and UDP stream re-origination can break
      coturn's own STUN/TURN allocation bookkeeping). Recommended fix
      is kernel-level DNAT (`iptables`/`nftables` port-range rule) on
      the edge host instead, paired with narrowing
      `coturn_min_port`/`coturn_max_port` down from the 16K-port
      default. **Not implemented** — this is new scope (no DNAT
      capability exists anywhere in `ops` yet); tracked as an open
      question in `homecloud-infra`, not built this session.
- **Inventory/worlds consolidation** — DONE. `terraform-worlds` and
  `homelab_ansible_inventory` merged into one private repo,
  `homecloud-infra`; the Terraform world renamed `world-01` →
  `production`; `ops`'s symlinks and justfile (`default_world`,
  `link-externals`) updated to match.
- **Incus role/module support** — DONE. Ported hivecraft-infra's
  `incus-host`, `incus-image-pin`, and `firewall` Ansible roles, plus its
  `terraform/modules/incus` OpenTofu module (as a Terraform-provider
  equivalent — this repo stays on Terraform, see Tech Stack above), into
  this repo as generic, reusable boilerplate: no hardcoded hostnames/IPs,
  secrets routed through `group_vars` per the existing convention, CIDR
  lists and channel/image-alias values exposed as role variables rather
  than baked in. This was the prerequisite for any Proxmox→Incus
  migration (the maintainer's own homelab migration plan lives in the
  private `homecloud-infra` repo, not here — see this session's Status
  note); that repo can now actually execute its migration runbook.
  - ✅ `terraform/modules/incus/1.1/{instance,profile}` — ported, both
    submodules `terraform validate` clean. Deliberate genericness change
    from hivecraft-infra's version: `image` has **no default** (hivecraft
    defaults to its own pinned alias name, which is homelab-specific
    branding, not something a public boilerplate module should assume) —
    pin your own image via the new `incus-image-pin` role and pass the
    alias in. Versioned directory (`1.1/`, the targeted provider minor
    version) matches this repo's `terraform/modules/proxmox/qemu-vm/`
    convention rather than hivecraft's `v1/` scheme.
  - ✅ `ansible/roles/incus-image-pin` — ported near-verbatim (already
    fully generic in hivecraft-infra, no homelab-specific content to
    strip). Neutral default alias (`debian-13`, not hivecraft's
    `hivecraft-debian-13`). Syntax-check clean; `ansible-lint`'s only
    finding is the repo-wide hyphenated-role-name pattern already present
    on every other hyphenated role here (`nginx-proxy`, etc.) — not a
    regression, already tracked under Tech Debt.
  - ✅ `ansible/roles/incus-host` — ported. Syntax-check and
    `ansible-lint` clean (same single pre-existing hyphenated-name
    finding as every other role, 20 files checked). Three deliberate
    genericness changes from hivecraft-infra's version, documented in
    the role's own README: `incus_dropbear_enable` now defaults `false`
    (hivecraft's hosts all use LUKS; this role doesn't assume that),
    `incus_network_bridge_dns` now defaults `[]` (was a live IP),
    and a new `incus_install_ipmitool` var (default `false`) replaces
    hivecraft's hardcoded exclusion based on their specific hardware's
    lack of a BMC. Task comments/fail messages pointing at hivecraft's
    `docs/runbooks/*.md` paths were reworded — this repo doesn't ship
    those runbooks (see the repo-boundary note in CLAUDE.md).
  - ✅ `ansible/roles/firewall` — ported near-verbatim (already fully
    generic in hivecraft-infra, only path examples in the README
    adjusted to this repo's inventory layout). Closes the "no host
    firewall anywhere in this repo" gap noted in `homecloud-infra`'s
    `docs/network.md`. Syntax-check clean; `ansible-lint` passes at the
    `production` profile with **zero** findings (the role name has no
    hyphen, so it doesn't hit the repo-wide hyphenated-name finding the
    other two roles do). The rendered nftables ruleset itself is
    byte-for-byte the same template hivecraft-infra runs in production;
    Jinja rendering was verified locally (both a fully-flagged-on and a
    minimal render), but a real `nft -c -f` syntax check needs
    `CAP_NET_ADMIN`/root and couldn't be run in this sandboxed
    environment — run it for real (`nft -c -f /etc/nftables.conf` or
    against a rendered copy) before the first apply to any host.

  All four pieces of this initiative are now done.
- **New-service roles from the strategy guide** — IN PROGRESS. The
  maintainer's homelab strategy doc (`gooseops_infra_plan.md`, now in
  `homecloud-infra`) named several services with no Ansible role here
  yet: Authentik/Keycloak (SSO), Restic (backup/DR), BookStack,
  Easy!Appointments, standalone Collabora, WorkAdventure, Uptime Kuma,
  MinIO, Gitea/Forgejo+CI. Building these one at a time, prioritized per
  the strategy doc's own ranking (SSO and backup/DR flagged
  non-optional) plus whatever a hivecraft-infra role exists to reuse.
  - ✅ `ansible/roles/authentik` — done. **Not a port** — hivecraft-infra's
    `authentik` role deploys via Helm onto its Kubernetes cluster, which
    this homelab doesn't run for internal services; built fresh as a
    Docker Compose stack (server + worker + bundled no-persistence
    Redis) matching this repo's existing app-role shape (`vaultwarden`,
    `nextcloud`): external shared Postgres (same pattern as
    synapse/vaultwarden/mattermost/odoo, not a bundled DB), TLS via the
    existing `nginx-proxy` role, optional S3-compatible media storage
    (off by default — no cloud dependency assumed). Stricter than this
    repo's older single-secret app roles on purpose: asserts all 4+
    required secrets are non-empty before doing anything, fails loud
    rather than silently deploying broken. `ansible-lint` clean at the
    `production` profile (0 findings); the rendered Docker Compose file
    verified with a real `docker compose config` (both the default and
    S3-enabled variants), not just YAML parsing. See the role's own
    README for the full "why not a port" reasoning and prerequisites.
  - ✅ `ansible/roles/restic` — done. Not a port (no equivalent role in
    hivecraft-infra — that repo's backup story is pgBackRest→R2,
    Postgres-specific, not a generic host-backup pattern). Landed after
    a conversation with the maintainer clarified the actual need: an
    existing NFS file server currently backs up "some machines" with
    nothing automated (no versioning, retention, or integrity
    checking). Designed around independent per-dataset **jobs**
    (`restic_jobs`, each with its own repository/password/schedule/
    retention) rather than one flat backup — deliberately, since
    Terraform state and a Nextcloud dump don't want the same retention
    policy even on the same host, and a media library (discussed and
    explicitly scoped out — large, replaceable, not what restic's
    dedup/versioning is for) shouldn't be lumped in with either. Each
    job gets two systemd timer pairs (`restic-backup-<name>`,
    `restic-check-<name>` for periodic integrity verification, not just
    backup) — cron was deliberately not used, matching this session's
    systemd-timer convention (coturn). Optional NFS mount via
    `ansible.posix.mount` (already a repo dependency), off by default
    since many hosts will already have their target mounted some other
    way. Runs the first backup immediately at deploy time and asserts a
    snapshot actually landed, rather than trusting the timer will
    eventually fire correctly.
    - **Caught two real bugs via actual execution, not just
      syntax-check**, in the templated backup script: (1) blank lines
      Jinja's `{% for %}` tags leave in the rendered output were
      silently breaking a multi-line `\`-continued `restic backup`
      command into several broken standalone commands — `bash -n`
      (syntax-only) didn't catch this, `shellcheck` did (SC2215), and
      the fix (bash arrays instead of line-continuation) was verified
      by actually running the rendered script against a stub `restic`
      binary and inspecting argv. (2) A `"${arr[@]:-}"` fallback added
      defensively for `set -u` safety turned out to itself inject a
      spurious empty-string argument when the array was legitimately
      empty (no excludes configured) — caught the same way, by running
      it and inspecting actual argv, not by reasoning about it
      abstractly. Removed; bash 4.4+ (every target OS here) handles
      empty-array expansion under `set -u` correctly without it.
      `ansible-lint` clean at the `production` profile (0 findings, 11
      files); `shellcheck` clean on the rendered script in both a
      multi-path/multi-exclude and a single-path/no-exclude
      configuration.
  - ✅ `ansible/roles/easyappointments` — done. Not a port (no equivalent
    in hivecraft-infra). Pulled forward out of the strategy-doc's
    priority order specifically because the maintainer's updated
    website needs a working "book a call" button — Nextcloud aggregates
    calendars, this handles the actual booking page/logic, paired via
    Easy!Appointments 1.5+'s native two-way CalDAV sync (a per-provider
    admin-UI setting, not role-managed config — see the role's README).
    Docker Compose stack matching this repo's app-role shape, but with
    one real deviation worth remembering: this is the first app role
    here needing MySQL/MariaDB rather than Postgres, and there's no
    shared MySQL/MariaDB role to point it at yet (unlike authentik/odoo/
    synapse/vaultwarden/mattermost's shared-external-`postgresql`-role
    pattern) — so it bundles a MariaDB container in its own compose
    stack instead, **with a persistent volume** (unlike authentik's
    bundled Redis, which is deliberately non-persistent cache/broker
    state — this database is the actual appointment/customer/provider
    data). Verified current image/env vars via the official
    `alextselegidis/easyappointments-docker` docs rather than guessing
    (same discipline as the Odoo wkhtmltopdf research) — official image
    only gained version tags at 1.5.0. Initially pinned to `1.5.2`
    without checking whether a newer stable had shipped since — it had
    (1.6.0, released 2026-05-28, well before this role was built); the
    maintainer caught and fixed the version pin directly, now `1.6.0`.
    Not asserted as a hard requirement, but SMTP config is functionally
    required (booking confirmations/reminders/provider notifications
    all go out by email) — README calls out the `mail`-protocol
    fallback the container silently uses if left unconfigured.
    **Deployed and live** — the maintainer has run the playbook against
    the real host, logged into the admin panel, and set Theme (Darkly)
    + Company Color (`#065222`, matched to `gooseops-website`'s brand
    green — found via that repo's own CSS custom properties, converted
    to RGB). Also hardened after a real problem the maintainer hit
    running it live: the upstream image ships neither an `.htaccess`
    nor `mod_rewrite` enabled, so CodeIgniter's raw URLs
    (`/index.php/login`) were the only thing that worked, and Apache
    leaked its version via the `Server` header/error pages. Fixed via
    two bind-mounted config files (`.htaccess` for URL rewriting,
    `apache-hardening.conf` for `ServerTokens`/`ServerSignature`) plus
    an `entrypoint:` override running `a2enmod rewrite` before Apache
    starts — checked the image's actual `docker-entrypoint.sh` first
    (no env-var-driven module-enable hook exists) rather than assuming
    a wrapper was necessary. Stays on the pinned upstream image, no
    custom build. Also picked up a real branded favicon
    (`easyappointments_favicon_url`, same read-only bind-mount
    mechanism, same three files it's bind-mounted alongside) — **first
    committed as a binary in this role's own `files/`, then corrected**:
    a branded icon is deployment-specific content, not generic reusable
    boilerplate, so it doesn't belong in the public `ops` repo at all —
    same public-boilerplate-vs-homelab-specific boundary already
    enforced for PLAN.md/`NOTES.md` content earlier this session, just
    not one I'd previously thought to apply to a binary asset. Re-done
    as an `ansible.builtin.get_url` fetch (`force: false`, downloads
    once) from `easyappointments_favicon_url`, set in
    `homecloud-infra`'s `group_vars/easyappointments.yml` to the live
    `gooseops-website` favicon URL — optional and off by default in the
    role itself. `ansible-lint` clean at the `production` profile (0
    findings, 8 files) in isolation; the rendered Docker Compose file
    verified with a real `docker compose config` in both a
    favicon-URL-set and favicon-URL-unset variant, confirming the
    conditional bind mount doesn't break either path.
  - ✅ `ansible/roles/freebusy-sync` — done. Not from the original
    strategy-doc list — added mid-session once the maintainer's
    "book a call" work surfaced a real dependency: Nextcloud aggregates
    calendars for Easy!Appointments to read, but nothing was pulling the
    maintainer's actual Google Calendar availability into Nextcloud in
    the first place. Deploys the maintainer's own pre-existing script
    (`files/sync_freebusy_to_nextcloud.py` — Google service account +
    domain-wide delegation → Nextcloud CalDAV, no OAuth/browser step
    ever) as a systemd service+timer pair, colocated on the `nextcloud`
    host (the script's only real dependency is its CalDAV write target;
    deliberately NOT on `cloud_proxy` — the service-account key has
    domain-wide delegation, too sensitive to put on the one
    internet-facing host). Explicitly considered and rejected a generic
    cron/task-runner role in favor of this single-purpose one — see the
    role's own README for the reasoning. The script itself + its
    `requirements.txt`/`.env.example` live in this role's own `files/`
    (moved there from a `scripts/calendar/` location mid-session, at the
    maintainer's request, once the role existed — no separate
    "single source of truth" split to maintain). Fully live-verified
    this session, both halves (rare for this repo's roles so far, most
    others are still syntax-checked/lint-clean only): the script's
    logic and credentials, run manually per the runbook's Step 9, and
    the actual Ansible deployment — `ansible-playbook
    nextcloud.playbook.yml` has now run for real against the Nextcloud
    host and the systemd timer is confirmed running in production.
    Caught and fixed a real script bug (missing
    RFC 5545-required `DTSTAMP` on generated `VEVENT`s) via the actual
    `caldav` library's compatibility warning during that live test run,
    not by reasoning about it in the abstract. Also surfaced and
    documented (in `homecloud-infra`'s
    `docs/runbooks/freebusy-sync-google-setup.md`) two non-obvious
    environment gotchas hit during that live test: a Nix/`PYTHONPATH`
    venv-isolation leak, and Nextcloud's calendar-delete-doesn't-free-
    the-URI trap (verified fix: `occ dav:delete-calendar -f <uid> <uri>`
    run while the calendar is still active, never after a UI delete).
    `ansible-lint` clean at the `production` profile (0 real findings —
    1 known/accepted hyphenated-role-name finding, same category as
    `incus-host`/`incus-image-pin`).
  - ⬜ Everything else in the list above (BookStack, Collabora,
    WorkAdventure, Uptime Kuma, MinIO, Gitea/Forgejo+CI) — not started.
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
- `openclaw` was managed via manual shell commands, not an Ansible role
  — moot now: the service was decommissioned from this homelab's
  inventory (`homecloud-infra`'s `PLAN.md`, 2026-07-27). Not fixing
  going forward unless it comes back.
- `.envs`/`.keys` setup (`just setup`/`use`) pulls the SSH key pair
  only; a GCP service-account key and/or kubeconfig pull (like
  hivecraft-infra's) were deliberately deferred until their Doppler
  secret names are confirmed.
- Odoo's `wkhtmltox` apt dependency chain is resolved in the role (see
  the Odoo service initiative above), but not yet verified against the
  actual manually-created VM — do that before considering this closed.
- `jitsi`/`coturn` hardening (see that initiative above) was never
  live-verified, and now isn't going to be against this homelab — both
  services were decommissioned from inventory (`homecloud-infra`'s
  `PLAN.md`, 2026-07-27). The `blockinfile`/`lookup('template', ...)`
  mechanism was tested standalone against a scratch file, and both
  roles pass syntax-check + `ansible-lint` + template-rendering checks,
  but nothing ever actually ran `jitsi-meet`/`coturn` end to end. The
  roles stay as generic reusable boilerplate; if they're ever deployed
  again (here or elsewhere), live-verify TURN relay negotiation for
  real before trusting them — this was flagged as a real gap, not
  closed by the syntax/lint checks alone.

---

## Open Questions

- Which `homelab.ini` groups/playbooks are actually live vs
  decommissioned vs needing touchups?
- **Resolved this session:** the ported `incus-host` role keeps
  hivecraft-infra's opinionated defaults for genuinely generic technical
  choices (Zabbly `lts-6.0` channel, LVM-thin storage assumptions) since
  those are sound recommendations regardless of consumer — but drops
  every default that was really homelab branding or hivecraft's specific
  hardware (pinned image alias name, a live DNS IP, LUKS-on-by-default,
  a hardcoded BMC-less-hardware assumption). See the role's own README
  "Adapted for genericness" section for the itemized list.
- Whether/when a second Doppler environment gets added (single `prod`
  today).
- Whether/when a `staging` or `development` world gets added under
  `homecloud-infra/worlds/` (the symlink + justfile already support it
  with no further change).

---

## Next Up

1. **Live-verify roles still untested against a real host** (`restic`,
   `odoo`, `authentik`, the Incus set) against a scratch Proxmox VM —
   everything so far is syntax-checked/`ansible-lint`-clean/template-
   rendered-and-tested-in-isolation, none of it has run against a real
   host. Step-by-step procedure, per role, with pass criteria (not just
   "did the command exit 0" — several bugs this session were exactly
   that kind of false positive): `docs/testing/role-validation-checklist.md`.
   Confirm the `ODOO_POSTGRESQL_*` group_vars entries in
   `homecloud-infra` are still current as part of the `odoo` pass
   specifically. `jitsi`/`coturn` dropped from this list — the homelab
   services they'd have been verified against were decommissioned from
   inventory (`homecloud-infra`'s `PLAN.md`, 2026-07-27); the roles
   themselves are still valid generic boilerplate, just nothing to
   live-verify them against right now. `easyappointments` is deployed
   and running against the real host now (admin panel reachable, first
   login done, Theme/Company Color set) — drop it from this checklist's
   backlog. Still open on it specifically: the Nextcloud CalDAV pairing
   and a real booking exercised end to end, not yet done (see
   `homecloud-infra`'s `PLAN.md` Next Up). `freebusy-sync` (a new
   role, not in the original strategy-doc list — see this file's
   new-service-roles initiative) is **fully done** — `ansible-playbook
   nextcloud.playbook.yml` has run for real against the Nextcloud host
   and the timer is confirmed running in production, on top of the
   script-logic/credentials verification from earlier. First role this
   session to get that complete treatment. See `homecloud-infra`'s
   `PLAN.md` and `docs/runbooks/freebusy-sync-google-setup.md`.
2. Reconcile `homelab.ini` + `ansible/roles` against live infra (the
   audit above) so this plan's Services table can drop its caveat.
3. Incus role/module support is done (Terraform module, `incus-image-pin`,
   `incus-host`, `firewall`). The maintainer's own homelab migration
   execution now picks this up from `homecloud-infra`'s migration
   runbook — nothing further to do here unless that execution surfaces a
   bug in one of the ported roles/modules.
4. Real `nft -c -f` validation of the `firewall` role's rendered
   template against a real host (couldn't be done in this sandboxed
   session — see the Incus role/module support initiative's firewall
   note above) before its first real apply anywhere.
5. Continue the new-service-roles work: BookStack/Collabora/
   WorkAdventure/Uptime Kuma/MinIO/Gitea in whatever order is wanted —
   see the initiative above.
