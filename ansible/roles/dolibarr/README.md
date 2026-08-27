# dolibarr role

Deploys [Dolibarr](https://www.dolibarr.org) (CRM + invoicing/quotes +
inventory + light accounting + project management) via Docker Compose,
using the official `dolibarr/dolibarr` image. Fronted by this repo's
existing `nginx-proxy` role for TLS — same shape as `vaultwarden` and
`authentik`.

## Why Dolibarr, and why Postgres

Picked as the replacement for this repo's `odoo` role after Odoo 19.0
turned out to have no working codename (its own package needs
noble/trixie, the wkhtmltopdf build it depends on only exists for
bookworm/jammy — see the `odoo` role's README for the full story).
Dolibarr covers the same ground (CRM, invoicing, inventory) without
either problem: it's a single self-contained container, no host-level
OS/PHP-version dependency chain to get wrong.

Dolibarr's official image supports both MySQL/MariaDB and PostgreSQL.
This role hardcodes `DOLI_DB_TYPE=pgsql` and does not expose MySQL as an
option — the point of choosing Dolibarr here is reusing this repo's
existing shared `postgresql` role/host (same pattern as `authentik`,
`synapse`, `vaultwarden`, `mattermost`), not bundling a second database
engine the way `easyappointments` has to for MySQL.

## Prerequisites

1. **Postgres.** This role does not create a database. Run the shared
   `postgresql` role against your DB host with a `dolibarr` entry added
   to `postgresql_databases`/`postgresql_users`/`postgresql_hba_entries`
   (in your inventory repo's `group_vars/postgresql.yml`). Then point
   `dolibarr_postgres_host`/`dolibarr_postgres_password` (and the rest,
   if you didn't use the defaults) at it.
2. **Secrets.** `dolibarr_postgres_password`, `dolibarr_admin_login`,
   `dolibarr_admin_password`, and `dolibarr_url_root` are all required —
   the role asserts and fails loud if any are empty. Source them through
   group_vars/host_vars, never hardcode them here.
3. **Reverse proxy.** This role only publishes plain HTTP on
   `dolibarr_http_port` (default `8083`) — TLS termination and the
   public hostname are the `nginx-proxy` role's job, configured via
   `nginx_proxy_configs` the same way every other app in this repo is
   fronted.

## PostgreSQL disables the automated installer — read this before first run

This is Dolibarr's own documented behavior, not a bug in this role:
`DOLI_INSTALL_AUTO` (which auto-runs the installer against MySQL/MariaDB
on first boot) **does not work with `DOLI_DB_TYPE=pgsql`** — confirmed
directly against the official `Dolibarr/dolibarr-docker` repo's own
README, not assumed. This role sets `DOLI_INSTALL_AUTO: "0"` explicitly
for that reason. `dolibarr_admin_login`/`dolibarr_admin_password` are
still passed to the container and still required by this role's assert,
but **they are not what becomes your actual admin account** when using
Postgres — the real admin account gets created interactively during the
manual wizard below, same general shape as `easyappointments`' and
`odoo`'s browser-based first-run steps. Unlike those two, though, the
follow-up step Dolibarr requires (creating `install.lock`) doesn't stay
manual — see below.

After this role's play finishes, one manual step remains — the one part
of this that genuinely can't be scripted, since it's an interactive
wizard:

1. Browse to `<dolibarr_url_root>/install` and complete the setup
   wizard (this is where you actually set the real admin login/password
   — pick something at least as strong as `dolibarr_admin_password`,
   they don't have to match).

That's it. **Creating `install.lock` is automated** — this role checks
whether Dolibarr's core `llx_user` table exists (real evidence the
wizard actually completed, not just that someone visited the page) and
creates the lock file itself once it does, via
`community.docker.docker_container_exec` rather than requiring a
manual `docker exec`. No toggle var to remember to flip — it's detected
from real database state on every run, so it also self-heals if
`install.lock` is ever removed by hand for an upgrade.

**Upgrading** an already-installed instance still needs the manual half
of this dance (Dolibarr's own requirement, not this role's): remove
`install.lock`, browse to `/install` again to run the DB upgrade — this
role will recreate `install.lock` on its next run once it sees the
schema is current again.
```bash
docker exec dolibarr-web /bin/bash -c "rm -f /var/www/documents/install.lock"
# browse to <dolibarr_url_root>/install, run the upgrade — then just
# re-run this role, it'll relock automatically.
```

## What this role does not do

- Doesn't run the install wizard for you — can't, it's an interactive
  step Dolibarr's own image requires for Postgres (see above).
- Doesn't configure Dolibarr modules, numbering masks, company info, or
  any other in-app setup — that's all through Dolibarr's own admin UI
  after first login, same as this repo's other app roles.
- Doesn't enable MySQL/MariaDB as an alternative backend — deliberately
  Postgres-only, see "Why Dolibarr, and why Postgres" above.
