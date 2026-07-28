# firewall role

Universal nftables firewall. Default-drop on `input` and `forward`,
default-accept on `output`. Intended to apply to every host in your
inventory, same as the `base` role.

Ported from the maintainer's other, fully private production repo
(hivecraft-infra), which runs this exact pattern in production. Already
fully generic in the source — no hardcoded IPs/hostnames to strip, just
adjusted path examples below to match this repo's inventory layout (a
single flat `homelab.ini` + `ansible/inventory/group_vars/`, not
hivecraft-infra's multi-environment layout).

## What it allows

| Source | Port | Purpose |
|---|---|---|
| `firewall_management_cidrs` | 22/tcp | SSH |
| `firewall_metrics_cidrs` | `firewall_metrics_tcp_ports` (default `[9100]`) | metrics scrape (node-exporter, etc.) |
| `firewall_cluster_cidrs` | `firewall_extra_tcp_ports` | per-host-class TCP |
| `firewall_cluster_cidrs` | `firewall_extra_udp_ports` | per-host-class UDP |
| anywhere | ICMP / ICMPv6 | ping, path MTU discovery |
| `lo` | any | loopback |

`established,related` is always accepted; `invalid` is always dropped.

## Configuration is required

The three CIDR lists (`firewall_management_cidrs`,
`firewall_metrics_cidrs`, `firewall_cluster_cidrs`) default to empty. The
role asserts they are non-empty before doing anything else, so an
unconfigured environment fails loud rather than rendering a default that
is almost certainly wrong for the surrounding network. Set them in
`ansible/inventory/group_vars/all.yml` (or a tighter scope) before the
first run.

## Per-host-class extension

Set `firewall_extra_tcp_ports` / `firewall_extra_udp_ports` in a
group-specific `group_vars/<group>.yml`. For Incus hosts, for example:
8443/tcp (Incus API) and 8472/udp if you're running Incus's built-in
OVN/VXLAN networking.

## Cilium pod traffic on Kubernetes nodes

Set `firewall_allow_pod_forward: true` on host classes that route pod
traffic. When true, the rendered ruleset accepts traffic on
Cilium-managed interfaces in both the input chain (`cilium_*` and
`lxc*` ingress — needed for same-node pod-to-host traffic, which
keeps its pod source IP because Cilium's masquerade only fires on
egress that physically leaves the host) and the forward chain
(`cilium_*` and `lxc*` ingress + egress — needed for cross-node pod
traffic and pod-to-internet egress). Off by default; hosts that don't
route pod traffic should stay strict.

## Lockout safety

`nft -c -f` validates the rendered config before it lands. The handler
issues `systemctl reload nftables`, which atomically replaces the
ruleset — there is no window where the host is unfirewalled. If
validation passes but the new ruleset blocks your SSH source CIDR you
will be locked out; recovery then depends on whatever out-of-band access
your hardware has (console, BMC/IPMI, or physical access) — always
double-check `firewall_management_cidrs` covers your devbox before
applying.
