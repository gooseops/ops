# odoo role

Installs Odoo (native apt package from nightly.odoo.com, not a
container — unlike most other app roles in this repo) plus its PDF
report rendering dependency, wkhtmltopdf.

## Read this before touching wkhtmltopdf

A previous manual install attempt on this homelab hit an unresolvable
apt dependency chain trying to install wkhtmltopdf
(`fontconfig`/`libjpeg62-turbo`/`libx11-6`/`libxcb1`/`libxext6`/
`libxrender1`/`xfonts-75dpi`/`xfonts-base` all reported "not
installable"). That looked like "this OS is too new for wkhtmltopdf,"
which matches a lot of old folklore about needing an older Ubuntu/
Debian release for Odoo to work. **It isn't actually an OS-age
problem.**

What's actually going on: Odoo needs the "with patched qt" wkhtmltopdf
build, which isn't in any distro's own apt repos — it ships as a
separate `.deb` from `github.com/wkhtmltopdf/packaging`, one build per
OS codename (bookworm, trixie, jammy, noble, ...). If you install a
`.deb` built for the *wrong* codename (an old bionic/focal build on a
newer host, say — an easy mistake if you're following an older guide),
its declared dependency versions don't exist on the newer host and you
get exactly the "not installable" wall this repo hit. As of this
writing, the patched 0.12.6.1-3 build has confirmed-working `.deb`s for
Debian 12/13 and Ubuntu 22.04/24.04 — including whatever OS this
homelab's Odoo VM actually runs (the inactive `do_later` Terraform draft
for it clones an `ubuntu-noble-amd64` template, which also happens to be
Odoo's own currently-documented supported platform for its official
package).

This role's fix, in order (see `tasks/ubuntu-odoo.yml`):

1. Assert `ansible_distribution_release` is in
   `odoo_wkhtmltopdf_supported_releases` — fails loud instead of
   guessing, with a pointer to check the packaging project's releases
   page if the running codename isn't on the list yet.
2. Install the prerequisite runtime libraries via normal `apt` *first*,
   from whatever current versions the host's own repos carry.
3. Remove any unpatched `wkhtmltopdf` the distro's own repos might have
   shipped (same package name, silently missing rendering flags Odoo
   needs — a second, quieter way to end up with broken PDFs even after
   "successfully" installing something called wkhtmltopdf).
4. Download the **codename-matched** patched `.deb` (dynamic on
   `ansible_distribution_release`, never a hardcoded old codename).
5. Install it via `apt`'s `deb:` parameter (resolves dependencies
   against the repos configured in step 2 automatically).
6. **Actually verify it**: run `wkhtmltopdf --version` and assert the
   output contains `with patched qt`. This is the step a "did apt exit
   0" check would have missed — verify the real binary, not just that
   installation didn't error.

If you're troubleshooting a future failure here, re-read this list in
order before assuming it's an OS problem again.

## Prerequisites

1. **Postgres.** This role does not create a database. Run the shared
   `postgresql` role against your DB host with an `odoo` entry in
   `postgresql_databases`/`postgresql_users`/`postgresql_hba_entries`
   (this homelab's inventory repo already has `ODOO_POSTGRESQL_*`
   group_vars entries from when the VM/db were first created manually —
   confirm they're still current).
2. **Secrets.** `odoo_postgres_password` and `odoo_admin_passwd` are
   required — the role asserts and fails loud if either is empty.
   `odoo_admin_passwd` gates Odoo's database management screens
   (create/drop/duplicate/restore), not per-user logins — treat it like
   a root-adjacent credential.
3. **Reverse proxy.** This role only exposes plain HTTP on
   `odoo_http_port` (default `8069`) — TLS and the public hostname are
   the `nginx-proxy` role's job, same as every other app here.

## Multi-worker / production mode

`odoo_workers` defaults to `0` (Odoo's single-process dev mode — fine
for a homelab-scale instance). Setting it above `0` switches
`odoo.conf` into `proxy_mode` (expects `nginx-proxy` to set
`X-Forwarded-*` headers) but does not yet wire up `longpolling_port` or
a dedicated worker-count tuning pass — treat >0 as a starting point to
extend, not a fully-tuned production config.

## What this role does not do

Business configuration — installed apps, company/localization setup,
users beyond the initial admin — happens through Odoo's own UI after
first boot, not through this role. This role gets a healthy, correctly
PDF-rendering Odoo instance running; everything after that is normal
Odoo administration.
