# coturn role

Deploys a [coturn](https://github.com/coturn/coturn) STUN/TURN server
via Docker Compose, wrapped in a systemd unit. Primarily built to give
this repo's `jitsi` role a working TURN relay for NAT traversal — see
that role's README for how the two connect.

## This role was rewritten from an incomplete state — read this if you're diffing against an older version

An earlier version of this role wrote a Docker Compose file to disk and
stopped there: it never templated `turnserver.conf` (the compose file
referenced it as a bind mount, but nothing ever created it), never
installed or enabled the systemd unit that's supposed to run the
container, and the systemd unit template itself referenced
`docker-compose.yaml` while the file actually written was named
`docker-compose.yml` — that unit would have failed to start even if it
*had* been installed. The stock `turnserver.conf` shipped as the
template was also, functionally, the upstream example file with two
placeholder lines left live: an uncommented `cli-password=CHANGE_ME`
and an uncommented `mysql-userdb=...password=CHANGE_ME...` pointing at
a MySQL instance that doesn't exist anywhere in this stack. None of
this was caught before because the role was never actually exercised
against a live host. It is now a complete, self-contained deploy:
directory → cert → compose file → `turnserver.conf` → systemd unit →
enabled and started → verified actually running via
`docker_container_info`, not just "did `systemctl start` exit 0."

## Solving TURN behind CGNAT

This is the part that mattered most and was never wired up before. If
this host doesn't have a real public IP directly on its network
interface — a home network behind CGNAT, most consumer ISP setups —
every relay address coturn hands out by default is its own private
address, which is useless to clients on the public internet. Set
`coturn_external_public_ip` and `coturn_external_private_ip` (both, or
neither — the role asserts) to fix this; they map directly to coturn's
`external-ip=<public>/<private>` directive.

**Where should this host actually live?** If it's genuinely behind
CGNAT with no port-forwarding option, `external-ip` alone can't save
you — it only helps with ordinary single-layer NAT, not carrier-grade
NAT, since you don't control the public side of a CGNAT mapping at all.
The robust fix is a real public IP somewhere in the path — this role
just needs *some* host with one; how you get there is out of its scope.

## Reaching coturn through an edge proxy + WireGuard

If your actual setup is a public edge host (a small cloud VM, matching
hivecraft-infra's edge-router pattern) proxying into a WireGuard-tunneled
origin, TURN splits into two halves that need different tools:

- **The TLS/TCP path (port 5349, or TURN-over-443 for networks that
  block everything else)** fits an SNI-passthrough stream proxy
  perfectly — the same mechanism an edge proxy would already be using
  for any other TURN-over-TLS traffic (nginx `stream` + `ssl_preread` +
  a `map $ssl_preread_server_name` routing table, no TLS termination at
  the edge). Extending that map with a `turn.<domain>` entry and an
  `upstream` block pointing at coturn's WireGuard-tunnel address is
  close to zero new infrastructure if that pattern already exists.
- **The UDP relay port range (`coturn_min_port`–`coturn_max_port`)**
  does *not* fit that mechanism, and this is likely where a previous
  attempt at this hit a wall. `ssl_preread`-based routing depends on
  reading a TLS ClientHello over a TCP connection — there's no
  equivalent for bare UDP, so nginx `stream` can't route the relay
  range the same way. Proxying it through nginx anyway means one
  `listen`/`proxy_pass` pair *per port* — real per-port memory/fd
  overhead, and nginx's UDP stream proxying re-originates each flow as
  a new UDP session toward the upstream, which changes the source port
  the backend sees unless carefully tuned — exactly the kind of
  mismatch that breaks coturn's own STUN/TURN allocation bookkeeping,
  since coturn expects a predictable mapping between the port a client
  thinks it's using and the port it's actually listening on.

  **DNAT (`iptables`/`nftables` `PREROUTING`/`nat` rules) is the right
  tool for this piece instead.** A single rule matching a port *range*
  (`--dport 49152:49500`) rewrites the destination address/port
  in-kernel, with no per-port listener, no extra proxy hop, and no
  flow re-origination — it's the same mechanism any router uses for
  ordinary port forwarding, and it composes naturally with a routed
  WireGuard interface (which is already an L3 tunnel, not an
  application-level proxy) in a way an application proxy doesn't.
  HAProxy doesn't change this calculus — its UDP support is newer and
  less proven than its TCP/HTTP path, and it has the same
  per-port-listener scaling shape as nginx for a wide range; it's a
  fine *alternative* to nginx for the SNI-passthrough TCP half (that's
  what hivecraft-infra's own edge design uses, via `req.ssl_sni`), but
  it doesn't solve the UDP-range problem any better than nginx does.

  **Narrowing `coturn_min_port`/`coturn_max_port`** to a few hundred
  ports (rather than the 16K-port default) keeps that DNAT rule and any
  matching firewall rule small and reviewable — how many you actually
  need is a capacity question (concurrent relayed sessions, which is
  usually a small minority of total calls since most participants find
  a direct or server-reflexive path without needing a full relay), not
  something this role can size for you.

Building the actual DNAT rule on the edge host is new scope — nothing
in `ops` implements it yet. Track it as its own piece of work, not
something either the `coturn` or `jitsi` role can configure from the
inside.

## Prerequisites

1. **DNS.** `coturn_domain` needs to actually resolve to this host
   (or wherever traffic for it lands) before the certbot step runs.
2. **Port 80 free during cert issuance/renewal.** `certbot certonly
   --standalone` briefly binds port 80 itself — this role doesn't
   install nginx (there's nothing for it to front), so there's normally
   no conflict, but note it if you've put something else on port 80.
3. **Firewall.** If you're running this repo's `firewall` role on this
   host too, it needs 3478/udp+tcp, 5349/udp+tcp, and the full
   `coturn_min_port`–`coturn_max_port` UDP range (default
   49152–65535) open from wherever your clients actually connect —
   that's a wide range and a real firewall-rule decision, not something
   this role configures for you.

## Auth modes

See `defaults/main.yml`'s comments for the full explanation —
`static_user` (default, a single long-term username/password) is what
this repo's `jitsi` role's client-side config can actually consume;
`secret` (coturn's TURN REST API, time-limited credentials) is more
robust but not wired into that role yet.

## Doppler secrets checklist

| Variable | Purpose |
|---|---|
| `coturn_static_username` / `coturn_static_password` | Required if `coturn_auth_mode: static_user` (the default) — must match `jitsi_turn_username`/`jitsi_turn_password` on whatever host runs `jitsi` |
| `coturn_static_auth_secret` | Required if `coturn_auth_mode: secret` — not currently consumed by the `jitsi` role, see that role's TURN section |
| `coturn_external_public_ip` / `coturn_external_private_ip` | Not secret, but real infra values — set both together or neither |
| `coturn_email` | Let's Encrypt account email, not secret but required |
