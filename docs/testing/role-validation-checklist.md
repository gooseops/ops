# Role & Playbook Validation Checklist

Everything below was written, syntax-checked, `ansible-lint`-clean, and
in several cases template-rendered/executed against stub binaries — but
none of it has run against a real host. This is the checklist for
closing that gap on a scratch Proxmox VM before trusting any of it
against real infrastructure.

Covers: `restic`, `odoo`, `authentik`, `easyappointments` (now deployed
live — see its section for what's still worth re-checking), `jitsi` +
`coturn` (paired — decommissioned from this homelab, kept for
reference), and the Incus role/module set (`incus-host`,
`incus-image-pin`, `firewall`, the Terraform `incus` module).

---

## Prerequisites

- A scratch Proxmox VM (or several — see per-section notes on whether a
  role needs its own VM or can share one). Match the OS to what the
  role actually targets — Debian 13 (trixie) for the Incus set, Ubuntu
  24.04 (noble) for `odoo` (matches its currently-documented supported
  platform), Debian 12/13 or Ubuntu 22.04/24.04 for everything else
  (all confirmed-working codenames for `odoo`'s wkhtmltopdf dependency
  if you want to reuse one VM across multiple roles).
- `nix develop` at the repo root — pins `ansible-playbook`, `ansible-lint`,
  `terraform`, and everything else referenced below.
- SSH access to the scratch VM with a key + user `just` can use (same
  `ANSIBLE_USER`/`ANSIBLE_SSH_PRVKEY`/`ANSIBLE_SSH_PUBKEY` Doppler
  pattern as real hosts — see `ops`'s `CLAUDE.md`).
- **Use a separate Doppler config for this, or throwaway values, not
  real `prod` secrets.** These VMs are disposable and this checklist
  has you writing secrets to disk on them (keystore passwords, repo
  passwords, moderator passwords) — don't reuse anything that
  protects real data.
- A way to add temporary inventory entries pointing at the scratch
  VM(s) — either a throwaway `group_vars`/`host_vars` overlay, or just
  target the VM directly with `-l <ip>` and `-e @vars.yml` for one-off
  testing without touching real inventory at all. The latter is
  simpler for this kind of testing and is what the command examples
  below assume.

---

## General methodology (apply to every role below)

1. **Syntax-check first** (should already pass — confirms nothing broke
   since this session):
   ```
   ansible-playbook --syntax-check <playbook>.yml
   ```
2. **`ansible-lint` the role** (should already be clean at `production`
   profile — confirms nothing broke):
   ```
   ansible-lint ansible/roles/<role>
   ```
3. **Apply for real** against the scratch VM.
4. **Verify functionally** — every per-role section below specifies
   what "actually works" means beyond "the playbook exited 0." A green
   Ansible run is necessary, not sufficient — several of the bugs this
   session found (coturn's missing systemd unit, the restic script's
   broken line-continuation) would have produced a green run.
5. **Re-run the playbook a second time.** Confirm it reports mostly
   `ok`, not `changed`, on the second pass (exceptions are noted
   per-role below — e.g. restic's "run the first backup now" task is
   *supposed* to report `changed` every run, that's not a bug). A role
   that isn't idempotent will bite you on every future deploy, not just
   this one.
6. **Note anything that didn't match the README/PLAN.md** — these docs
   describe what was *intended* and validated up to the point live
   testing wasn't possible; if reality disagrees, the docs are what's
   wrong, not a reason to silently work around it.

---

## Doppler / test secrets needed, consolidated

Set these once (as a test Doppler config or `-e` overrides) rather than
discovering them one role at a time:

| Var | Role | Notes |
|---|---|---|
| `odoo_postgres_password`, `odoo_admin_passwd` | odoo | |
| `authentik_secret_key`, `authentik_postgres_password`, `authentik_bootstrap_password`, `authentik_bootstrap_token` | authentik | |
| `coturn_static_username`, `coturn_static_password` | coturn | must match jitsi's values below |
| `jitsi_keystore_pass` | jitsi | |
| `jitsi_turn_username`, `jitsi_turn_password` | jitsi | must match coturn's values above |
| `jitsi_secure_domain_moderators[].password` | jitsi | pick a real test password, you'll use it to log in |
| `restic_jobs[].password` | restic | one per job |
| `easyappointments_db_password`, `easyappointments_db_root_password` | easyappointments | |
| `incus_dropbear_breakglass_public_key` | incus-host | only if testing the (opt-in, off by default) LUKS remote-unlock piece — skip for a first pass |

---

## Recommended order

1. **`easyappointments`** — already deployed and live in production
   (not blocked on this checklist anymore — the real deploy happened
   directly, with real issues found and fixed live rather than caught
   here first: a stale version pin, missing Apache `mod_rewrite`/
   `.htaccess`, no favicon customization). Still worth running this
   section as a regression check against a scratch VM, and the CalDAV
   round-trip test below is still an open item against the real
   deployment too — see `homecloud-infra`'s `PLAN.md`.
2. **`restic`** — simplest, fully self-contained, no dependency on
   anything else in this list. Good next test of the general
   methodology above.
3. **`odoo`** — the wkhtmltopdf dependency chain was the known
   troublemaker; test it in isolation before it's competing with other
   things on a shared VM.
4. **`authentik`** — self-contained Docker Compose stack, no
   dependencies on the other new roles.
5. **`coturn` then `jitsi`** — test coturn first and confirm it works
   standalone (STUN/TURN binding) before layering Jitsi's config on
   top, so a failure is attributable to one or the other.
6. **Incus set** (`incus-host`, `incus-image-pin`, `firewall`, the
   Terraform module) — most complex, most destructive (bridge cutover
   can disconnect the VM), do this last and make sure you have Proxmox
   console access before starting, not just SSH.

---

## 1. `easyappointments`

**What "works" means:** both containers healthy, the setup wizard
completes, a real booking actually goes through end to end (creates the
appointment AND sends the confirmation email — a booking that "succeeds"
with SMTP silently broken is a false pass), and — since this is the
actual point of pairing it with Nextcloud — a CalDAV sync round-trips.

```
cat > /tmp/easyappointments-test-vars.yml <<EOF
easyappointments_base_url: "http://<scratch-vm-ip>:8082"
easyappointments_db_password: "test-password-change-me"
easyappointments_db_root_password: "test-root-password-change-me"
easyappointments_mail_smtp_host: <a real test SMTP relay you can check delivery on>
easyappointments_mail_smtp_user: <...>
easyappointments_mail_smtp_pass: <...>
easyappointments_mail_from_address: test@example.com
EOF

ansible-playbook -i <scratch-vm-ip>, -u <user> \
  -e @/tmp/easyappointments-test-vars.yml \
  ansible/easyappointments.playbook.yml
```

- [ ] `docker compose -f /opt/easyappointments/docker-compose.yml ps`
      (on the VM) shows `app` and `mariadb` both `running`/healthy —
      `mariadb`'s healthcheck gating `app`'s startup via `depends_on:
      condition: service_healthy` means `app` shouldn't even attempt to
      start until this passes; confirm `app` didn't crash-loop against
      a not-yet-ready DB (check with `docker compose logs app` if it
      did).
- [ ] Browse to `easyappointments_base_url` and complete the first-run
      setup wizard (creates the admin account — there's no bootstrap
      env var, this step is genuinely manual).
- [ ] **Real booking test**: as a customer (no login), book an
      available slot against a test service/provider, and confirm the
      confirmation email actually arrives in the test SMTP relay's
      inbox — this is the check that proves `MAIL_SMTP_*` is correct,
      not just that the booking record landed in MySQL.
- [ ] **CalDAV sync test** (the actual reason this role exists): in the
      admin UI, edit the test provider → Calendar Sync, point it at a
      test Nextcloud Calendar's CalDAV URL + credentials, trigger a
      sync, and confirm the booking from the previous step appears in
      Nextcloud Calendar. Then create an event directly in Nextcloud
      Calendar during that provider's working hours and confirm it
      blocks that slot from being bookable in Easy!Appointments after
      the next sync — this is the two-way part, not just outbound.
- [ ] Re-run the full playbook. Expected: `docker_compose_v2` task
      reports `ok` on the second pass (no config drift), no container
      restarts.

---

## 2. `restic`

**What "works" means:** a backup actually completes, a **restore**
actually reproduces the original files (backup success alone doesn't
prove this), and pruning actually removes old snapshots per the
retention policy.

```
# Point restic_jobs at a small, disposable test directory first —
# don't back up anything real yet.
cat > /tmp/restic-test-vars.yml <<EOF
restic_jobs:
  - name: smoke-test
    repository: /mnt/restic-test-repo
    password: "test-password-change-me"
    paths:
      - /etc/hostname
      - /etc/hosts
    keep_daily: 3
EOF

ansible-playbook -i <scratch-vm-ip>, -u <user> \
  -e @/tmp/restic-test-vars.yml \
  ansible/restic.playbook.yml
```

- [ ] Role completes; the "Assert each job has at least one snapshot"
      task passes (this is the deploy-time functional check already
      built in — if it fails, stop here, don't proceed to the manual
      checks below).
- [ ] `restic -r /mnt/restic-test-repo snapshots` (with
      `RESTIC_PASSWORD` set) shows the snapshot.
- [ ] **Restore test**: `restic -r /mnt/restic-test-repo restore latest
      --target /tmp/restore-test`, then `diff -r /tmp/restore-test/etc
      /etc` (adjust paths) and confirm no differences.
- [ ] Modify one of the backed-up test files, wait for
      `RandomizedDelaySec` or manually run
      `systemctl start restic-backup-smoke-test.service`, confirm a
      second snapshot appears.
- [ ] Manually run `systemctl start restic-check-smoke-test.service`,
      confirm it exits 0 (`systemctl status` / journal).
- [ ] Re-run the full role. Expected: password file / systemd unit
      tasks report `ok`; the "run the first backup now" task reports
      `changed` (expected every run — it's supposed to take a fresh
      backup every apply, not skip); the snapshot-assertion task passes
      again.
- [ ] If testing `restic_nfs_mount_enabled: true`: confirm the mount
      actually landed (`mount | grep restic`) and survives a reboot
      (`reboot`, wait, re-check).

---

## 3. `odoo`

**What "works" means:** wkhtmltopdf's patched build is actually
installed (not the unpatched distro one), and Odoo can actually
generate a PDF — not just that `apt install` exited 0.

```
cat > /tmp/odoo-test-vars.yml <<EOF
odoo_postgres_host: <scratch postgres host or same VM if you also run the postgresql role>
odoo_postgres_database: odoo_test
odoo_postgres_user: odoo_test
odoo_postgres_password: "test-password-change-me"
odoo_admin_passwd: "test-admin-change-me"
EOF

ansible-playbook -i <scratch-vm-ip>, -u <user> \
  -e @/tmp/odoo-test-vars.yml \
  ansible/odoo.playbook.yml
```

- [ ] The "Assert this OS release has a known-working .deb" task
      passes (confirms the VM's OS codename is in
      `odoo_wkhtmltopdf_supported_releases` — if it fails here, that's
      the check working as intended, not a bug: add the codename only
      after confirming a matching `.deb` actually exists at
      github.com/wkhtmltopdf/packaging/releases).
- [ ] The "Verify the patched binary actually runs" assertion passes
      (`wkhtmltopdf --version` containing `with patched qt`) — **this
      is the check that would have caught the original failure**, so
      don't skip past it even if everything else looks fine.
- [ ] Log into the Odoo web UI (`http://<vm-ip>:8069`), the initial
      database-creation screen should appear (using `odoo_admin_passwd`
      as the master password).
- [ ] Create a database, install a module that generates PDFs (Sales or
      Invoicing is the standard smoke test), create a test
      quotation/invoice, **click "Print" and confirm an actual PDF
      downloads and renders correctly** — this is the real end-to-end
      proof wkhtmltopdf works, not just that the binary exists.
- [ ] Re-run the full playbook. Expected: apt/wkhtmltopdf tasks report
      `ok` (the `creates:` guards should skip re-downloading/
      re-installing); no errors.

---

## 4. `authentik`

**What "works" means:** all three containers healthy, the web UI is
reachable, and the bootstrap admin can actually log in.

```
cat > /tmp/authentik-test-vars.yml <<EOF
authentik_secret_key: "test-secret-key-change-me-50-chars-minimum-xxxxxxxxxxxxxxxx"
authentik_postgres_host: <scratch postgres host>
authentik_postgres_password: "test-password-change-me"
authentik_bootstrap_password: "test-admin-change-me"
authentik_bootstrap_token: "test-token-change-me"
EOF

ansible-playbook -i <scratch-vm-ip>, -u <user> \
  -e @/tmp/authentik-test-vars.yml \
  ansible/authentik.playbook.yml
```

- [ ] `docker compose -f /opt/authentik/docker-compose.yml ps` (on the
      VM) shows `server`, `worker`, and `redis` all `running`/healthy.
- [ ] Browse to `http://<vm-ip>:9000/if/flow/initial-setup/` (or the
      root URL) and confirm the Authentik login page loads.
- [ ] Log in as `akadmin` with `authentik_bootstrap_password`.
- [ ] Re-run the full playbook. Expected: `docker_compose_v2` task
      reports `ok` on the second pass (no config drift), no container
      restarts.

---

## 5. `coturn` then `jitsi`

**Not currently actionable against this homelab** — both services were
decommissioned from inventory (`homecloud-infra`'s `PLAN.md`,
2026-07-27), so there's no live host to run this against right now.
Left in place since the roles remain valid generic boilerplate; run
this section for real before trusting either role again, whether that's
here (if these come back) or elsewhere.

Test coturn alone first — if TURN doesn't work end-to-end, you want to
know whether the problem is coturn itself or Jitsi's config before
debugging both at once.

### 5a. `coturn`

```
cat > /tmp/coturn-test-vars.yml <<EOF
coturn_domain: turn-test.example.com   # needs to actually resolve to the scratch VM
coturn_email: test@example.com
coturn_static_username: testuser
coturn_static_password: "test-password-change-me"
EOF

ansible-playbook -i <scratch-vm-ip>, -u <user> \
  -e @/tmp/coturn-test-vars.yml \
  ansible/coturn.playbook.yml
```

- [ ] The "Assert the container is running" task passes (deploy-time
      check already built in).
- [ ] **Real STUN/TURN test**, not just "container is up" — use
      [Trickle ICE](https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/)
      (or `turnutils_uclient` from the `coturn-utils` package if you'd
      rather test from the CLI) pointed at
      `turn:turn-test.example.com:3478` with the test username/password
      — confirm it returns a `relay` candidate, not just a `srflx`
      (server-reflexive) one. A `srflx`-only result means STUN works
      but TURN relay doesn't — the exact failure mode this role was
      built to fix.
- [ ] Re-run the playbook. Expected: `ok` across the board except
      possibly the systemd-unit templating tasks if you changed
      anything; container should not restart unnecessarily.

### 5b. `jitsi`

```
cat > /tmp/jitsi-test-vars.yml <<EOF
jitsi_domain: meet-test.example.com   # needs to actually resolve to the scratch VM
jitsi_email: test@example.com
jitsi_keystore_pass: "test-keystore-change-me"
jitsi_turn_host: turn-test.example.com
jitsi_turn_username: testuser              # must match coturn_static_username above
jitsi_turn_password: "test-password-change-me"  # must match coturn_static_password above
jitsi_secure_domain_enabled: true
jitsi_secure_domain_moderators:
  - username: testmod
    password: "test-mod-password-change-me"
EOF

ansible-playbook -i <scratch-vm-ip>, -u <user> \
  -e @/tmp/jitsi-test-vars.yml \
  ansible/jitsi.playbook.yml
```

- [ ] The "Assert core services are active" task passes
      (prosody/jicofo/jitsi-videobridge2 all running).
- [ ] `grep -A5 'ANSIBLE MANAGED BLOCK.*TURN' /etc/jitsi/meet/meet-test.example.com-config.js`
      shows the expected `p2p.stunServers` block with the right host/
      credentials.
- [ ] **Secure domain**: open `https://meet-test.example.com` in a
      private/incognito window (no saved session) and try to start a
      new meeting — should be rejected or redirected to a login prompt,
      **not** silently create the room.
- [ ] Log in as `testmod` (the moderator account) and confirm you
      *can* create a meeting.
- [ ] With the meeting running, open the same meeting URL in a second
      browser/incognito window as a guest — should join without
      needing an account (via the `guest.meet-test.example.com`
      domain).
- [ ] **Real TURN-in-use test**: join the call from a client forced
      through a restrictive network path (mobile hotspot with a
      symmetric NAT, a VPN, or just block UDP outbound on one client's
      firewall temporarily) and confirm the call still connects. Check
      `chrome://webrtc-internals` (or Firefox's `about:webrtc`) for a
      `relay`-type candidate pair in use, or check
      `journalctl -u coturn-docker` on the coturn host for allocation
      log lines during the call.
- [ ] Re-run both playbooks. Expected: `ok` across the board; the
      `blockinfile` tasks in particular should report no changes on a
      second pass (this is the part that was verified standalone
      against a scratch file earlier — confirming it holds up against
      the real package-generated files is the point of this test).

---

## 6. Incus set (`incus-host`, `incus-image-pin`, `firewall`, Terraform module)

**Secure Proxmox console access to the scratch VM before starting this
section** — the bridge cutover step can disconnect SSH if anything's
misconfigured, and console access is the only way to recover from that.

### 6a. `incus-host` (bridge cutover disabled first)

```
cat > /tmp/incus-host-test-vars.yml <<EOF
incus_network_bridge_apply: false   # leave the destructive step off for this first pass
EOF

ansible-playbook -i <scratch-vm-ip>, -u <user> \
  -e @/tmp/incus-host-test-vars.yml \
  <adapt: this role has no dedicated playbook yet — add it to a throwaway play, e.g.:>
  # - hosts: <scratch-vm-ip>
  #   roles: [incus-host]
```

- [ ] `ss -tlnp | grep 8443` shows Incus listening.
- [ ] `incus list` (on the VM, as the admin user — confirms the
      `incus-admin` group membership took effect; you may need a fresh
      SSH session for the new group to apply) works without `sudo`.
- [ ] The storage pre-flight assertion passes (or fails with a clear
      message if the VG doesn't have enough free space — either is
      "working correctly," just confirm the message is accurate for
      what's actually on the VM).

**Optional, only with console access confirmed working:** re-run with
`incus_network_bridge_apply: true` and real
`incus_network_bridge_uplink`/`_address`/`_gateway` values matching the
VM's actual NIC (`ip -br link` first — **don't trust a value from
another host**, this is the exact gotcha the role's README warns
about). Confirm the VM is still SSH-reachable afterward at its new
bridge-assigned address before considering this a pass.

### 6b. `incus-image-pin`

Requires `incus-host` to have succeeded first (needs a running Incus
daemon).

- [ ] After running, `incus image list` shows the pinned alias.
- [ ] Confirm it's the **VM** variant, not container:
      `incus image list <alias> -c lfdsut` and check the type column,
      or just try launching a VM instance from it.

### 6c. `firewall`

```
cat > /tmp/firewall-test-vars.yml <<EOF
firewall_management_cidrs: ["<your devbox IP>/32"]
firewall_metrics_cidrs: ["<your devbox IP>/32"]
firewall_cluster_cidrs: ["<scratch VM subnet>/24"]
EOF
```

- [ ] **Before applying**: confirm `firewall_management_cidrs` actually
      covers whatever IP you're SSHed in from — this is the "lock
      yourself out" footgun the README warns about.
- [ ] After applying, confirm SSH is still connected (it will be, since
      `nft -c -f` validates before the reload, but confirm anyway) and
      that a *new* SSH connection from your devbox IP still succeeds.
- [ ] From an IP **not** in `firewall_management_cidrs`, confirm SSH is
      actually blocked (if you have a second network path to test
      from) — proves the deny-by-default policy is real, not just
      that the allow rule works.
- [ ] `nft list ruleset` on the VM matches what you expect from the
      CIDR values you set.

### 6d. Terraform `incus` module

At minimum:
```
cd terraform/modules/incus/1.1/instance && terraform init -backend=false && terraform validate
cd ../profile && terraform init -backend=false && terraform validate
```
(Already done this session — should still pass; this just confirms
nothing regressed.)

**Full end-to-end** (optional, needs 6a+6b done first): write a real
`.tf` file using the `instance` module against the scratch VM's now-
running Incus daemon (via the provider's TLS client cert — see the
module README's provider block example), `terraform apply`, confirm
the instance actually boots and is SSH-reachable with the
`ssh_authorized_keys` you provided, then `terraform destroy` to clean
up.

---

## Cleanup

- Destroy/reset the scratch VM(s) via Proxmox once done — don't leave
  test credentials (Doppler test config, `/tmp/*-test-vars.yml` files)
  sitting around longer than needed.
- Delete the `/tmp/*-test-vars.yml` files from your devbox — they
  contain the test passwords in plaintext.
- If anything in this checklist surfaces a real bug, fix it in the
  role, re-run the specific section that failed, and update the
  relevant `PLAN.md` entry to reflect "verified live" rather than
  "syntax-checked only."
