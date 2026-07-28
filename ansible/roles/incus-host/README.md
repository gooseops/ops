# incus-host role

Installs and configures Incus on a hypervisor host. Applied to hosts in
whatever inventory group you use for your Incus cluster members.

Ported from the maintainer's other, fully private production repo
(hivecraft-infra), which runs this exact pattern in production. Adapted
here to be generic boilerplate — no hardcoded hostnames, IPs, or
homelab-specific defaults; see the "Adapted for genericness" section
below for what changed.

## What runs by default

1. Adds the Zabbly apt repository (`incus_zabbly_channel`, default
   `lts-6.0` — an LTS channel over `stable`: CLI/API stability matters
   more than bleeding-edge features for a hypervisor) and key.
2. Installs `incus` and, if `incus_install_ui` (default true),
   `incus-ui-canonical` (observability-only — provisioning stays in
   Terraform, not the UI).
3. Adds `{{ ansible_user }}` to the `incus-admin` group so Incus commands
   work without `sudo` (next login picks up the new group).
4. Enables and starts `incus.service`.
5. Sets `core.https_address` to `incus_listen_address` (idempotent —
   only writes when the current value differs).
6. Installs hardware metrics packages (`lm-sensors`, `smartmontools`,
   plus `ipmitool` if `incus_install_ipmitool` is true) when
   `incus_install_hardware_metrics` is true.
7. **Storage pre-flight** (`incus_storage_validate: true`, default on).
   Asserts the install-time volume group (`incus_storage_vg`, default
   `<hostname>-vg`) has at least `incus_storage_min_free_gib` GiB free
   for an Incus LVM-thin pool. Read-only — it does not create the pool.
   The cluster-wide pool is created post-clustering, once, by your own
   cluster-bootstrap runbook (not this role).
8. **e1000e NIC offload workaround** (`incus_e1000e_offload_fix: true`,
   default on). Drops a driver-matched udev rule disabling TX
   segmentation offload on any `e1000e` NIC — works around the
   "Detected Hardware Unit Hang" bug some onboard Intel I217/I218/I219
   controllers hit under load. Matched by driver, so it's a safe no-op
   on hardware without this NIC, and correct on every host with it
   without naming a specific interface. The rule fires at device add;
   the handler only reloads udev. **For a NIC that is already up, apply
   it once by hand — no reboot needed:**

   ```
   # <iface> is the physical uplink (e.g. eno1), even when enslaved to a bridge
   sudo ethtool -K <iface> tso off gso off
   # verify:
   ethtool -k <iface> | grep -E 'tcp-segmentation|generic-segmentation'
   ```

## What is gated off by default

These are opt-in via host_vars/group_vars because running them on the
wrong host, or without preparation, is destructive or assumes something
about your hardware this role doesn't assume by default:

- **Network bridge** (`incus_network_bridge_apply: true`). Converts the
  host's primary NIC into a bridge member and moves the host IP onto the
  bridge so VMs can attach directly to the network. Lockout-class
  operation — secure console/IPMI access before turning this on, not
  after, and verify the uplink interface name live (`ip -br link`)
  rather than trusting a value from a previous run or another host;
  predictable interface names vary by hardware/BIOS even on nominally
  identical machines.
- **dropbear-initramfs remote LUKS unlock** (`incus_dropbear_enable:
  true`, default **false**). SSH into the early-boot initramfs and run
  `cryptroot-unlock` remotely instead of typing a passphrase at the
  physical console — only relevant if your hosts use LUKS-encrypted
  root, which this role does not assume. Touches the boot chain if
  enabled; read `tasks/dropbear.yml` in full before the first run on any
  host, and canary on one host before rolling to the rest.

## Cluster init

`incus admin init` is intentionally not automated by this role. Cluster
bootstrap/join is an infrequent, high-stakes, shape-changing operation —
running it interactively (or via your own carefully-sequenced runbook)
keeps that decision deliberate rather than an Ansible side effect. See
whatever cluster-bootstrap runbook your consuming repo maintains.

## Adapted for genericness (vs. the source role)

If you're comparing against hivecraft-infra's version of this role:

- `incus_dropbear_enable` defaults to `false` here (it's `true` there,
  since every one of their hosts uses LUKS). This role doesn't assume
  LUKS encryption at all.
- `incus_network_bridge_dns` defaults to `[]` here (it carried a live
  IP as a default there). Set it per-environment.
- `incus_install_ipmitool` is a new variable here, default `false` —
  the source role hardcoded ipmitool's exclusion based on its own
  specific hardware's lack of a BMC. Flip it on per-host if your
  hardware actually has one.
- References to a specific runbook path (`docs/runbooks/...`) were
  removed from task comments/fail messages — this repo doesn't ship
  those runbooks (see the top-level CLAUDE.md's repo-boundary note: that
  kind of homelab-specific operational doc belongs in a consuming repo,
  not here). The warnings themselves are kept; the pointer to "read the
  runbook first" is now "understand this task file first."
