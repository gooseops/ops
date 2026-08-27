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
- **Odoo service** (branch `feat/odoo_role`, later hardening on
  `fix/harden_new_roles`) — role/playbook code DONE, **and now
  actually live and running** against the real VM (`192.168.1.101`,
  `ubuntu-noble-amd64`, `odoo_install_wkhtmltopdf: false`) — the first
  fully successful `just deploy odoo` this session, after working
  through an upstream Odoo 19.0/wkhtmltopdf codename conflict (see the
  live-testing bullet below and the role's own README) that had no
  clean fix at the OS level. Ansible role/playbook itself was written
  in an earlier session; this session live-tested it for the first
  time via `just deploy odoo`, caught and fixed eight real bugs along
  the way (two `wkhtmltopdf`/codename issues, a missing `gnupg`
  dependency, `resolute` separately turning out to be missing an
  unrelated Python package Odoo needs — not yet available in
  resolute's repos, exact package unconfirmed — a wrong claim in this
  session's own earlier reasoning: disabling `list_db` does *not* mean
  Odoo stops needing hba access to Postgres's `postgres` maintenance
  database, it only disables the web UI; removing that hba entry when
  `list_db` was disabled caused a real startup crash
  (`psycopg2.OperationalError: ... no pg_hba.conf entry for host ...
  database "postgres"`), fixed by restoring it in `homecloud-infra`'s
  `group_vars/postgresql.yml` — and, the last one: with `list_db =
  False`, nothing was left to actually initialize a fresh database's
  schema, since that's normally the web install wizard's job and the
  wizard is exactly what's disabled. Every request 500'd with `relation
  "ir_module_module" does not exist` in
  `/var/log/odoo/odoo-server.log` (not the systemd journal — the
  package's own unit redirects Odoo's real logging to a file, a real
  gotcha on its own worth remembering next time this looks silent).
  Fixed by adding a `community.postgresql.postgresql_query` check
  (`to_regclass('public.ir_module_module')`) plus a conditional
  `odoo -i base --stop-after-init` run to the role, so a fresh database
  gets schema-initialized automatically instead of requiring a manual
  one-off command — that init task itself then hit bug seven, a known
  Ansible pitfall: `become_user` to an unprivileged user without SSH
  pipelining tries a BSD-style ACL `chmod` mode string GNU/Linux chmod
  rejects (`invalid mode: 'A+user:...:allow'`); fixed with
  `ansible_ssh_pipelining: true`, the same pattern this role and
  `postgresql` already use everywhere else a task becomes a non-root
  user. **Bug eight, caught live right after**: `-i base` doesn't set a
  known/usable password on the `admin` res.users account either (no
  OpenERP-era "admin/admin" default) — added an `odoo_admin_user_password`
  var + a task piping a small script into `odoo shell` to set it.
  Getting this task's idempotency right took two more wrong attempts,
  both worth remembering: (1) first version gated it on
  `odoo_schema_check`'s condition ("only run on a genuinely fresh
  schema"), which looked equivalent but wasn't — the maintainer had run
  the role (not by hand) enough times that schema init had already
  happened in an earlier pass, so `odoo_schema_check` reported "already
  initialized" on the next run and silently skipped the password task
  too, for the wrong reason. (2) Second attempt checked
  `res_users.password IS NOT NULL` directly instead — sounds like the
  right question, confirmed live it wasn't: `-i base` itself sets *some*
  non-NULL value on that column (a random, unknown hash, not blank), so
  the check was already true before this task ever ran even once, and
  it silently skipped every single time — `just deploy odoo` reported
  clean success both times, no error anywhere, admin locked out with a
  password nobody knows. Fixed for real with a local sentinel file
  (`/etc/odoo/.admin_password_set`, via the command's own `creates:`)
  instead of trying to infer intent from Odoo's internal DB state — same
  pattern as `dolibarr`'s `install.lock`/`suitecrm`'s `config.php`
  `creates:` guard elsewhere in this repo) before landing on the working
  `noble` + no-PDF-rendering combination. `ansible-lint` clean at the
  `production` profile (0 findings, 7 files); syntax-check clean
  including the multi-worker
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
    hit before. **Correction (live-testing session, see below): the
    "confirmed via web search" claim here was wrong.** The pinned
    0.12.6.1-3 release was last published 2023-05-22 — checked directly
    against the GitHub Releases API asset list, not assumed — and its
    only real `amd64` builds are `bookworm`, `bullseye`, and `jammy`.
    `noble` (Apr 2024) and `trixie` (Aug 2025) postdate the release
    entirely; no build for either can exist. This surfaced as a live
    404 downloading against a `noble` host. **Further correction: `jammy`
    isn't a clean fix either** — see the blocker note below, this turned
    out to be a deeper structural gap than a wrong-codename mistake.
  - The role installs prerequisite libraries before the codename-matched
    `.deb`, removes any distro-shipped unpatched `wkhtmltopdf`, and — the
    part a simpler role would skip — actually runs `wkhtmltopdf
    --version` and asserts `with patched qt` appears in the output
    before proceeding to install Odoo itself, rather than trusting a
    clean `apt` exit code. Unsupported OS codenames fail loud with a
    pointer to the packaging project's releases page instead of
    guessing. Full reasoning in the role's own README — read it before
    touching the wkhtmltopdf block again if this breaks in the future.
  - **Live-tested against the real VM this session** (first role in the
    "untested against a real host" backlog to actually go through this).
    Caught two real bugs the syntax-check/lint-clean/template-rendered
    checks couldn't have caught: (1) the `noble`/`trixie` release claim
    above, wrong as described; (2) `libjpeg62-turbo`
    (`odoo_wkhtmltopdf_prereq_packages`) is a Debian-only package name —
    Ubuntu (jammy/noble/questing/resolute) ships the identical runtime
    library as plain `libjpeg62`, confirmed via packages.ubuntu.com.
    `apt` failed with "No package matching 'libjpeg62-turbo' is
    available," which reads like a missing repo and isn't one. Fixed:
    the prereq task now branches on `ansible_distribution`. Also
    involved two VM codename changes in `homecloud-infra`'s
    `worlds/production/odoo.tf` this session — `ubuntu-resolute-amd64`
    (26.04, no wkhtmltopdf build exists for it, ever) → `ubuntu-noble-amd64`
    (24.04, postdates the pinned wkhtmltopdf release, same problem) →
    `ubuntu-jammy-amd64` (22.04, fixes wkhtmltopdf but broke on the next
    task instead — see below). `ansible-lint` clean at the `production`
    profile (0 failures, 7 files) after both fixes.
  - **BLOCKED, now retesting Bookworm**: `jammy` gets past wkhtmltopdf
    but then fails installing the Odoo package itself — `odoo : Depend:
    python3-lxml-html-clean but it is not installable`. Root cause
    confirmed, not guessed: Odoo's own `.deb` requires
    `python3-lxml-html-clean`, an apt package that only exists starting
    at `noble`/`trixie` (confirmed against both distros' package
    search) — a live, open, unresolved upstream bug, not specific to
    this homelab or to Odoo 19.0 specifically: `odoo/odoo#236599`
    reports the identical failure on Debian 12 for 19.0,
    `odoo/odoo#206725` reports the same failure for 18.0 — pinning an
    older Odoo version doesn't route around it. Checked whether Odoo's
    own `github.com/odoo/wkhtmltopdf` fork has a newer-codename build
    that'd let `noble` work instead — no, same `bookworm`/`jammy`-only
    asset list, last built as a "nightly" 2024-02-08. On paper: **no
    codename currently satisfies both Odoo's package and wkhtmltopdf
    simultaneously.**
    - **Reopened after the maintainer shared a screen recording of the
      original manual setup**: that session got Odoo fully running on
      Debian Bookworm, including hitting and working around the exact
      `libjpeg62-turbo` naming issue this role now automates, and
      independently discovering Trixie has no wkhtmltopdf build —
      matching this session's findings exactly. The live
      `worlds/production/odoo.tf` had drifted to `ubuntu-resolute-amd64`
      by the time this session started, nowhere near the
      previously-verified-working Bookworm. Likely explanation for the
      apparent contradiction with the GitHub issues above:
      `nightly.odoo.com` serves the current nightly build of a version
      branch, not a frozen snapshot, so the `.deb`'s dependency
      declarations could easily have changed since that recording.
      Maintainer's firsthand prior result outweighs the GitHub issue
      threads.
    - **Resolved (for now): deployed on `noble` with wkhtmltopdf
      skipped entirely**, live-confirmed by the maintainer — Odoo's own
      `.deb` installs and runs cleanly on `noble` (it's the
      `python3-lxml-html-clean` requirement that's satisfied there, not
      the wkhtmltopdf side). Added `odoo_install_wkhtmltopdf` (see the
      role's `defaults/main.yml`), gating the entire wkhtmltopdf
      block — including its own codename assert — behind one var.
      **Defaults `false`, deliberately, not `true`**: as of this
      writing no known codename makes `true` complete a working deploy
      end to end (`bookworm`/`jammy` pass wkhtmltopdf then fail
      installing Odoo itself; `noble`/`trixie` fail immediately at
      wkhtmltopdf's own codename assert) — defaulting to `true` would
      just be defaulting to "fails somewhere." Maintainer is also
      retesting `resolute` with the same flag — no role change needed
      for that, `python3-lxml-html-clean` is confirmed available there
      too and `odoo_install_wkhtmltopdf: false` skips wkhtmltopdf's
      codename gate entirely. Trade-off: no PDF report rendering until
      either upstream project ships a working combination — full
      writeup in the role's own README under "Known blocker."
      `ansible-lint` clean at the `production` profile (0 failures, 7
      files) after this change.
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
  - ✅ `terraform/modules/incus/v1/{instance,profile}` — ported, both
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
  - ✅ `ansible/roles/dolibarr` — done, drafted overnight after Odoo hit
    the unresolvable upstream blocker documented above. Not in the
    original strategy-doc list — a direct CRM replacement for Odoo, same
    "CRM, eCommerce, accounting, inventory, project management" territory,
    picked over Twenty (no invoicing/quotes — doesn't cover what Odoo was
    for), SuiteCRM (real contender, native LAMP install is actually
    low-risk — checked directly, it's a mainstream PHP/MariaDB stack with
    no equivalent of wkhtmltopdf's archived-dependency trap — but needs
    its own bundled MariaDB same as `easyappointments`), and EspoCRM
    (Postgres support still experimental as of v7.4). Chose Dolibarr
    specifically because its Postgres support is real, not experimental,
    letting it reuse this repo's existing shared `postgresql` role/host —
    same pattern as `authentik`/`synapse`/`vaultwarden`/`mattermost` —
    rather than bundling a second database engine. Docker Compose stack
    (single `dolibarr/dolibarr:23.0.3` container, current stable verified
    against Docker Hub's tag list directly, not assumed), `DOLI_DB_TYPE`
    hardcoded to `pgsql` rather than exposed as a role option, since
    Postgres-reuse is the entire reason this role exists. Fronted by the
    existing `nginx-proxy`/`nginx-base` roles, same shape as every other
    app role here.
    - **One real first-run wrinkle, confirmed against Dolibarr's own
      `Dolibarr/dolibarr-docker` README directly rather than assumed**:
      `DOLI_DB_TYPE=pgsql` disables the image's automated installer
      (MySQL/MariaDB-only) — first run needs a manual visit to
      `<url>/install` to complete the setup wizard, then creating
      `install.lock` inside the container's documents volume
      (`docker exec dolibarr-web /bin/bash -c "touch
      /var/www/html/documents/install.lock"`) before the app leaves
      installer mode. Same shape as `easyappointments`'/`odoo`'s
      browser-based first-run steps, just with this one extra
      Dolibarr-specific step — documented in full in the role's README,
      including the upgrade-path variant of the same dance.
    - `ansible-lint` clean in isolation (0 failures, 6 files); the
      rendered Docker Compose file verified by direct Jinja rendering
      and YAML-parsed, not just syntax-checked. `ansible-playbook
      --syntax-check` clean against the full playbook (docker + dolibarr
      + nginx-base + nginx-proxy).
    - **Now live**, chosen over `suitecrm` after Odoo's saga made the
      maintainer prioritize automation over feature depth. Provisioned:
      VM `192.168.1.104` (`worlds/production/dolibarr.tf`, vmid 104,
      `ubuntu-noble-amd64`), `[dolibarr]` inventory group, a `dolibarr`
      entry added to `homecloud-infra`'s `group_vars/postgresql.yml`
      (db/user/hba, reusing the shared host as designed), and a new
      `group_vars/dolibarr.yml` (`dolibarr.goose.local`, VPN-only,
      private cert — same pattern as `vaultwarden`/`jellyfin`/`odoo`,
      distinct domain from odoo's `crm.goose.local` since odoo is
      staying live alongside this rather than being decommissioned).
      Doppler secrets created: `DOLIBARR_POSTGRESQL_DB_NAME`/`DB_USER`/
      `USERNAME`/`USERPASS`, `DOLIBARR_ADMIN_PASSWORD`.
    - **Install-lock automation added post-deploy**: the maintainer
      completed the one genuinely-manual step (the browser install
      wizard, required because `DOLI_DB_TYPE=pgsql` disables
      `DOLI_INSTALL_AUTO`) and asked for the follow-up `install.lock`
      step to stop being manual too. Investigated Dolibarr's own
      `install.forced.php` silent-install mechanism first (a real,
      core-level equivalent to SuiteCRM's `config_si.php` — checked
      `htdocs/install/step1.php` etc. directly, all reference
      `/etc/dolibarr/install.forced.php` as a fallback path) as a way to
      skip the wizard entirely on *future* fresh installs, and separately
      considered dropping Postgres for bundled MariaDB (fully
      documented, zero-manual-step path, same shape as
      `easyappointments`) — maintainer was already mid-wizard by the
      time this was being evaluated, so neither was pursued further this
      session; both remain real options if `dolibarr` needs a from-scratch
      redeploy later. What did ship: the role now detects wizard
      completion itself (`SELECT to_regclass('public.llx_user') ...` —
      `llx_` is Dolibarr's own default table prefix, so the core user
      table existing is real evidence, not just "someone visited the
      page") and creates `install.lock` via
      `community.docker.docker_container_exec` automatically, no manual
      toggle var — deliberately rejected a human-flipped flag in favor
      of detecting real state, same reasoning as the odoo admin-password
      fix above (a toggle has to be remembered and correctly re-flipped;
      a state check doesn't). Self-heals if `install.lock` is ever
      removed for an upgrade. Live-tested this fresh check immediately:
      `postgresql_query` runs on the *dolibarr* host, not the postgres
      host, and — unlike `odoo`, which gets `psycopg2` for free as an
      actual dependency of the `odoo` package — nothing on a fully
      containerized host like this one ever installs it. Added a
      `python3-psycopg2` apt task, same as the `postgresql` role installs
      for itself. `ansible-lint` clean at the `production` profile (0
      findings, 6 files); syntax-check clean.
    - **Fully live-verified end to end** — `install.lock` confirmed
      present, `/install` now shows Dolibarr's own "setup disabled"
      message instead of the wizard, admin login works at the real app
      root, and the maintainer created and logged into a second user
      with no workaround needed — a real contrast with `odoo`, where a
      second user landed in "pending invite" limbo with no SMTP
      configured and needed the same `odoo shell` password-setting
      trick as the admin bootstrap. `dolibarr` is the first of the two
      CRM candidates (`dolibarr`/`suitecrm`) to reach this level of
      verification; `suitecrm` is still only lint-clean and
      template-verified, not deployed.
  - ✅ `ansible/roles/suitecrm` — done, drafted overnight alongside
    `dolibarr` at the maintainer's request, specifically to compare the
    two rather than commit to one. Pinned to the 7.15.x line (Extended
    Support Release, 2+ years of support from Dec 2025) rather than 8.x,
    per the maintainer's direction. Native LAMP install (Apache + PHP +
    its own MariaDB, all apt-installed) rather than Docker — checked
    directly and there's no reliable official SuiteCRM Docker image
    (Bitnami's went commercial-only, community images fragmented/stale)
    — but confirmed this is a fundamentally different risk than Odoo's
    wkhtmltopdf problem: SuiteCRM is a plain PHP/MariaDB app, every apt
    package this role installs is an unversioned meta-package
    (`php`, `php-mysql`, `libapache2-mod-php`) that resolves correctly
    per-codename automatically, no per-codename branching needed
    anywhere in this role.
    - **Runs its install fully unattended** — a real, documented,
      officially-supported SuiteCRM mechanism (`config_si.php` +
      `install.php?goto=SilentInstall`), verified against a real working
      example from a project's own CI pipeline before trusting it, not
      assumed from docs alone. This is the one clear automation
      advantage over `dolibarr`, whose Postgres mode has no equivalent
      and needs a manual browser wizard step.
    - SuiteCRM has never supported Postgres (its entire SugarCRM-lineage
      history is MySQL-family only) — this role bundles and manages its
      own native `mariadb-server`, a real operational cost `dolibarr`
      doesn't have (that role reuses the existing shared `postgresql`
      role/host). Added `community.mysql` to `ansible/requirements.yml`
      for this — this repo had never needed MySQL-family Ansible modules
      before, only `community.postgresql`.
    - Confirmed the exact download URL is the real packaged build
      artifact, not a raw git-tag checkout missing vendor/build
      output — traced suitecrm.com's own download button through its
      redirect chain to the GitHub release asset directly, not assumed.
    - **Caught and fixed one real bug before it shipped**: the Apache
      vhost template originally passed the full `suitecrm_url_root`
      (with `https://` scheme) straight into Apache's `ServerName`
      directive, which expects a bare hostname — would have produced a
      broken/warning-throwing vhost config. Caught by actually rendering
      the template through Ansible's own Jinja environment (a plain
      Jinja2-only test script missed it, since `regex_replace` — the
      fix — is an Ansible-provided filter, not stock Jinja2; had to
      re-verify through `lookup('ansible.builtin.template', ...)` to
      trust the fix). Fixed via
      `suitecrm_url_root | regex_replace('^https?://', '') |
      regex_replace('/$', '')`.
    - Apache's own default port-80 `Listen` directive is reassigned to
      `suitecrm_http_port` (default `8084`) and the default site removed,
      so the host's nginx (`nginx-base`/`nginx-proxy`) can own `80`/`443`
      the same as every other app role here — SuiteCRM is the first role
      in this repo where the app's own web server (not a container) has
      to be told to get out of nginx's way.
    - `ansible-lint` clean in isolation (0 failures, 8 files);
      `ansible-playbook --syntax-check` clean against the full playbook
      (suitecrm + nginx-base + nginx-proxy — no `docker` role, unlike
      every containerized app role here).
    - **Now being live-tested** — VM `192.168.1.106`, `[suitecrm]`
      inventory group, `group_vars/suitecrm.yml` (`suitecrm.goose.local`,
      VPN-only, same pattern as `odoo`/`dolibarr`), Doppler secrets
      created (`SUITECRM_DB_ROOT_PASSWORD`/`DB_PASSWORD`/
      `ADMIN_PASSWORD`). Confirmed the extra moving parts prediction
      above was right — two real bugs on the very first `just deploy
      suitecrm` attempt:
      1. `php-imap` unavailable — but only because the VM was
         accidentally still on `ubuntu-resolute-amd64`, not `noble` as
         this role assumes (same resolute-immaturity pattern that hit
         `odoo` twice already). First guess was a universe-component gap
         on noble specifically and `php-imap` got dropped from the
         required list; corrected once the real cause (wrong codename
         entirely) came out — restored it, `packages.ubuntu.com`
         confirms it's genuinely available on noble.
      2. **Real MariaDB auth-plugin bug, distinct from the resolute
         mixup**: setting a real password on `root@localhost` via
         `community.mysql.mysql_user`'s `password:` flips its auth
         plugin away from `unix_socket` to password-based — confirmed
         live by the very next task failing with "Access denied for
         user 'root'@'localhost' (using password: NO)". The
         `login_unix_socket`-only approach (mirroring the `postgresql`
         role's `become_user: postgres` peer-auth pattern) doesn't
         survive past the task that sets the password. Fixed with
         `check_implicit_admin: true` — `community.mysql`'s own
         documented answer to this exact bootstrapping problem: try a
         passwordless implicit connection first (works pre-password),
         fall back to the explicit `login_user`/`login_password`
         otherwise (works on every run after). No plugin-forcing or
         guessing needed, and it's now idempotent across repeated runs
         either way.
      3. **Third bug, same recurring class as #2**: the silent-installer
         task (`become_user: www-data`) hit the identical BSD-style ACL
         `chmod` failure already confirmed and fixed for `odoo`'s
         admin-init task this session — `become_user` to an unprivileged
         user without `ansible_ssh_pipelining: true` tries an ACL mode
         string GNU/Linux `chmod` rejects. This is now the second role
         to hit it; worth checking any *future* `become_user` task in
         this repo for the same var before it ships, not just after a
         live failure. `ansible-lint` clean at the `production` profile
         (0 findings, 8 files) after all three fixes.
- **`postgresql` role hardening** (this session, prompted by pre-Odoo
  testing) — DONE for the two smaller gaps, TLS deferred (see Tech
  Debt). Added: (1) an assert that `postgresql_superuser_password` is
  non-empty and isn't still the literal `"changethis"` placeholder
  default, plus a second assert that every `postgresql_users` entry has
  a non-empty `userpass` — this role (the shared dependency five other
  app roles build on) previously had no such check while every other
  app role in this repo does. The per-user check uses a single
  aggregate `selectattr`-based assert rather than looping over
  `postgresql_users` with `item` — looping would put each item
  (including its plaintext password) into the task result, which would
  then need `no_log`, and `no_log` on an `assert` also swallows the
  custom `fail_msg` on failure, leaving just "output hidden" instead of
  an actionable error. (2) Added the role's first `README.md` —
  previously undocumented despite backing five other roles — covering
  the secrets requirement, and the fact that `postgresql_pg_hba`/
  `postgresql_user`/`postgresql_db` are append/update-only and never
  prune a removed entry (this is exactly what required the manual
  `DROP DATABASE`/`DROP ROLE`/hand-edit-`pg_hba.conf` cleanup done this
  session for leftover odoo and mattermost test entries — now written
  down instead of tribal knowledge). `ansible-lint` clean at the
  `production` profile (0 failures, 5 files).
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
- Odoo has no PDF report rendering — `odoo_install_wkhtmltopdf` is
  `false` (the working default) because of a real upstream conflict
  (Odoo 19.0's package vs. wkhtmltopdf's available builds, no
  overlapping codename), not a role bug. See the Odoo service
  initiative above and the role's README. Revisit if either upstream
  project ships a fix; not actively being worked around beyond that.
- `postgresql` role has no TLS support (`ssl_cert_file`/`ssl_key_file`/
  `ssl=on` are never touched in `postgresql.conf`) — a `hostssl` entry
  in `postgresql_hba_entries` wouldn't actually work without separately
  provisioning certs first, so cross-host connections from app hosts
  (odoo, synapse, vaultwarden, mattermost) currently cross the LAN in
  plaintext. Doesn't need a public CA — the DB host and its clients are
  all LAN-only, so a self-signed/internal cert is sufficient. Surfaced
  during a review of the `postgresql` role prompted by Odoo testing;
  not fixed this session (bigger than the two gaps that were fixed
  alongside it — see the role's own README, which now documents this).
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
   `authentik`, `dolibarr`, `suitecrm`, the Incus set) against a scratch
   Proxmox VM — `dolibarr`/`suitecrm` additionally each need their own VM
   provisioned and inventory group before either can even start (see the
   new-service-roles initiative above); they're deliberately meant to be
   compared against each other before picking one, not both deployed
   permanently — `odoo` has now gone through this pass (see below) —
   everything so far is syntax-checked/`ansible-lint`-clean/template-
   rendered-and-tested-in-isolation, none of it has run against a real
   host. Step-by-step procedure, per role, with pass criteria (not just
   "did the command exit 0" — several bugs this session were exactly
   that kind of false positive): `docs/testing/role-validation-checklist.md`.
   `odoo` has now been through this live-verify pass and is **live and
   running** — confirmed the `ODOO_POSTGRESQL_*` group_vars, caught and
   fixed four real role bugs (see that initiative for the full list),
   worked through a genuine upstream blocker (Odoo 19.0 vs. wkhtmltopdf,
   no overlapping codename) by deploying with PDF rendering off rather
   than waiting on upstream. Drop it from this checklist's backlog — done,
   not blocked, with the one known accepted gap (no PDF reports)
   tracked in Tech Debt. `jitsi`/`coturn` dropped
   from this list — the homelab
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
