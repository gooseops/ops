# jitsi role

Installs self-hosted Jitsi Meet (Prosody + Jicofo + Jitsi Videobridge,
native apt packages from download.jitsi.org and packages.prosody.im)
with your own TLS certificate.

## TURN server — read this before assuming it's handled

An earlier deployment of this role was confirmed working for basic
calls but was **never configured with a TURN server**. Without one,
calls only work when both participants' NATs happen to allow a direct
UDP path to each other — fine on the same LAN, unreliable to broken the
moment either side is behind CGNAT, which is the normal case on most
home/mobile networks, not an edge case. This is the gap this role now
closes, but it's worth understanding what it does and doesn't solve:

- **`jitsi_turn_*` vars** (on by default — `jitsi_turn_enabled: true`,
  asserted non-empty if so) configure Jitsi Meet's client-side P2P
  mode: `config.p2p.stunServers` gets a STUN entry and a TURN/TURNS
  entry pointing at your TURN server, with a long-term-credential
  username/password. This is templated as a small append-only block
  (`ansible.builtin.blockinfile`, idempotent, verified in isolation
  before landing in this role) into
  `/etc/jitsi/meet/<domain>-config.js`, added as top-level statements
  *after* the package's own `config = {...}` declaration rather than
  editing that declaration in place — this works regardless of the
  exact shape/version of the base file the `jitsi-meet` package ships,
  and mutating `config.p2p` afterward is unaffected by whether that
  base declaration used `var` or `const`.
- **This uses a static, long-lived credential, not coturn's more
  modern time-limited REST-API mode.** The
  [official Jitsi TURN setup docs](https://jitsi.github.io/handbook/docs/devops-guide/turn/)
  explicitly flag the static-credential approach as functional but not
  ideal — the credential is visible to every client and never expires
  on its own. It's what this role implements because it's what a plain
  `config.js` can consume directly without extra moving parts; wiring
  up JVB's own time-limited-credential integration instead is a real
  future improvement, not implemented here. Pair this role's
  `jitsi_turn_username`/`jitsi_turn_password` with the `coturn` role's
  `coturn_auth_mode: static_user` (the default on that role) and
  matching `coturn_static_username`/`coturn_static_password`.
- **`jitsi_jvb_nat_harvester_enabled`** (off by default) is a
  *different* problem: it's for when this Jitsi host itself doesn't
  have a real public IP on its own interface and needs to advertise a
  public/private address pair for ICE candidates (JVB's
  `ice4j.harvest.mapping.static-mappings`, appended into
  `/etc/jitsi/videobridge/jvb.conf` the same append-only way). This is
  independent of whether you've configured a TURN server — you may
  need one, the other, both, or neither, depending on where this host
  actually sits on your network. That's a topology question this role
  can't answer for you.
- **What this role does not implement:** having JVB itself relay media
  through the TURN server when direct UDP fails (as opposed to the
  client-side P2P TURN config above, which only covers Jitsi's direct
  peer-to-peer mode before a call escalates to needing the bridge at
  all). The exact current config surface for that wasn't verified
  against a live instance before writing this role — see the official
  TURN setup docs linked above before assuming it's covered.

**Where should the TURN server actually run?** See the `coturn` role's
own README, "Reaching coturn through an edge proxy + WireGuard"
section — if your setup already runs an SNI-passthrough nginx `stream`
proxy in front of a WireGuard tunnel for other services, that same
pattern covers TURN's TLS/443 path for free. The part that pattern
*doesn't* cover — the wide UDP relay port range — is a genuinely
separate piece, worth deciding deliberately rather than assuming it
falls out of the same mechanism.

## Secure domain — user auth for meeting creation

Also worth flagging as an easy gap to leave open by accident: out of
the box, anyone who can reach this Jitsi instance can create a meeting,
not just join one. `jitsi_secure_domain_enabled` (off by default) closes
this:

- Prosody's main `VirtualHost` authentication switches from the
  package's default `"anonymous"` to `"internal_hashed"` (a targeted
  `lineinfile` substitution on the `authentication = ...` line,
  verified against a realistic sample of the package-generated file
  before landing in this role — it only touches that one line,
  indentation preserved).
- A separate `guest.<domain>` `VirtualHost` (subdomain configurable via
  `jitsi_secure_domain_guest_subdomain`) is appended with
  `authentication = "jitsi-anonymous"` — this is what lets people *join*
  an existing meeting without an account, while only accounts on the
  main domain can *create* one. No DNS/TLS/web-server config needed for
  it; it's internal to Jitsi/Prosody.
- Jicofo gets an `authentication { enabled: true, type: XMPP,
  login-url: ... }` block (append-only, same HOCON-merge mechanism as
  the JVB NAT block) so it actually rejects room-creation requests from
  unauthenticated JIDs — without this, the Prosody-side change alone
  does nothing.
- `config.js` gets `hosts.anonymousdomain` pointed at the guest
  subdomain, so the client knows to route anonymous joins there.
- `jitsi_secure_domain_moderators` — accounts registered via
  `prosodyctl register` on this host. **Required, non-empty, if secure
  domain is enabled** — the role asserts this, because turning secure
  domain on with zero registered accounts locks *everyone* out of
  creating meetings, not just anonymous users. Re-running the role
  resets each account's password to whatever's currently in
  `jitsi_secure_domain_moderators` — treated as inventory-managed,
  same philosophy as the `base` role's exclusive `authorized_key`.

This is entirely separate from inter-component authentication
(Jicofo/JVB's own connection to Prosody) — that part is **already
handled automatically** by the `jitsi-meet-prosody` package's own
`postinst` script (it generates the component secrets and creates the
internal `focus`/`jvb` Prosody accounts itself, every install). Nothing
in this role, or in a from-scratch setup, needs to touch it.

## Doppler secrets checklist

Everything this role needs sourced through your inventory repo's
`group_vars`/`host_vars` (never hardcoded, never a `lookup('env', ...)`
in this role's own `defaults/`) — this is the actual list, so nothing
gets lost track of again:

| Variable | Purpose |
|---|---|
| `jitsi_keystore_pass` | Java keystore password (TLS cert import) |
| `jitsi_turn_username` / `jitsi_turn_password` | Client-side TURN credential — must match `coturn_static_username`/`coturn_static_password` on whatever host runs coturn |
| `jitsi_jvb_public_address` / `jitsi_jvb_local_address` | Not secret, but real infra values — only needed if `jitsi_jvb_nat_harvester_enabled` |
| `jitsi_secure_domain_moderators[].password` (per account) | Prosody login password for each meeting-host/moderator account |

Matching values needed on the `coturn` side (see that role's own
Doppler checklist): `coturn_static_username`/`coturn_static_password`
(or `coturn_static_auth_secret` if using `secret` mode — not currently
consumed by this role, see the TURN section above).

## Known-uncertain idempotency

`community.general.java_cert`'s `state: present` is documented as
checking for an existing matching keystore entry before re-importing,
so it should already be idempotent by design — this wasn't re-verified
against a live host as part of this pass, unlike the `blockinfile`
tasks above (which were tested in isolation). The `certbot certonly`
task now has a `creates:` guard on the cert file it's responsible for
producing, which fixes the previous version's unconditional re-run on
every play (Ansible would report "changed" every time regardless of
whether certbot actually did anything) — note this only guards *first
issuance*; renewal is certbot's own systemd timer's job, not this
role's.
