# easyappointments role

Deploys [Easy!Appointments](https://easyappointments.org) (appointment
scheduling / booking pages) via Docker Compose: the app container plus a
bundled MariaDB. Fronted by this repo's existing `nginx-proxy` role for
TLS — same shape as `authentik`/`vaultwarden`/`nextcloud`.

## Why the database is bundled, not external

Every other app role in this repo that needs a relational database
(`authentik`, `odoo`, `synapse`, `vaultwarden`, `mattermost`) points at
this homelab's shared, external Postgres host instead of running its
own. Easy!Appointments needs MySQL/MariaDB, and there's no shared
MySQL/MariaDB role here yet to point it at — so this role bundles a
MariaDB container in the same compose stack instead, **with a
persistent volume**. That's a real difference from `authentik`'s
bundled Redis (which deliberately has no persistence, because it's pure
cache/broker state) — this database holds every appointment, customer,
and provider record, i.e. the actual application data. If a shared
MySQL/MariaDB role gets added later, this is a reasonable candidate to
switch over to it; not done now because no other role needs one yet.

## Prerequisites

1. **Secrets.** `easyappointments_base_url`, `easyappointments_db_password`,
   `easyappointments_db_root_password` are required — the role asserts
   and fails loud if any are empty. Source them through group_vars/
   host_vars, never hardcode them here.
2. **`easyappointments_base_url` must be correct before first run.**
   Unlike a typical reverse-proxied app, Easy!Appointments bakes this
   URL into things it generates at runtime — booking-confirmation email
   links, the public booking-page URL providers hand out — rather than
   deriving it from the incoming request. Changing it later means
   re-checking anything already sent out, not just updating a config
   value.
3. **Reverse proxy.** This role only publishes plain HTTP on
   `easyappointments_http_port` (default `8082`) — TLS termination and
   the public hostname are the `nginx-proxy` role's job, configured via
   `nginx_proxy_configs` the same way every other app in this repo is
   fronted.
4. **SMTP.** Not asserted as required (so a demo/internal instance can
   come up without it), but functionally the product doesn't work
   without it — booking confirmations, reminders, and provider
   notifications all go out by email. Leave `easyappointments_mail_smtp_host`
   unset and the container falls back to the image's own `mail`
   protocol default (PHP's local `mail()`), which does nothing useful
   without a local MTA on the container — set the `easyappointments_mail_*`
   vars to a real SMTP relay before treating this as production-ready.

## Pairing with Nextcloud Calendar

The maintainer's intended flow is Nextcloud aggregating calendars, with
Easy!Appointments handling the actual booking page/logic. As of
Easy!Appointments 1.5, that pairing is a supported first-class feature:
two-way CalDAV sync, one CalDAV calendar per provider. It is **not**
role-managed config — there's no environment variable for it. After
first login, each provider connects their own Nextcloud CalDAV calendar
URL + credentials through the Easy!Appointments admin UI (Providers →
edit provider → Calendar Sync). Known limitation from upstream: only
one CalDAV calendar per provider, and recurring events aren't fully
supported — plan the provider's Nextcloud calendar layout accordingly
if that matters for your setup.

## Scheduled calendar sync

Neither Google Calendar sync nor CalDAV sync polls the remote calendar
on its own — Easy!Appointments' [own console docs](https://easyappointments.org/documentation/console/)
say sync "can only be triggered from the Easy!Appointments backend or
whenever there are changes in the appointment plan" locally. A change
made directly on the remote side (a provider edits their actual Google
Calendar or Nextcloud calendar, not through Easy!Appointments) never
reaches Easy!Appointments until something calls its
`php index.php console sync` CLI command — so without a scheduled
trigger, the "Pairing with Nextcloud Calendar" setup above only ever
syncs one direction promptly (Easy!Appointments → remote, on booking)
and catches up on the other direction (remote → Easy!Appointments)
only when someone happens to open the backend.

This role deploys that command as a systemd service+timer pair
(`easyappointments_sync_enabled`, default `true`) — a timer, not
`ansible.builtin.cron`, matching this repo's existing convention (see
`restic`, `freebusy-sync`). `easyappointments-sync.service` runs
`docker exec easyappointments-app php index.php console sync` as a
`Type=oneshot` unit; `easyappointments-sync.timer` fires it on
`easyappointments_sync_on_calendar` (default `minutely`, matching
`freebusy-sync`'s own interval — same class of risk: a stale remote
calendar can let a customer double-book a slot the provider already
took elsewhere). Enabling sync for any given provider is still only
ever done in the admin UI (see above) — this just makes sure it
actually runs on a schedule once it is.

## Apache config: clean URLs + hardening

The upstream image (`php:8.2-apache` based) ships with neither an
`.htaccess` at `/var/www/html/` nor `mod_rewrite` enabled — out of the
box you get CodeIgniter's raw URLs (`/index.php/login`,
`/index.php/?service=2`) instead of clean ones, and Apache leaks its
version in error pages and the `Server` header (`ServerTokens`/
`ServerSignature` left at their defaults). This role fixes both without
building a custom image — it stays on the pinned upstream
`alextselegidis/easyappointments` tag (`easyappointments_version` in
`defaults/main.yml`):

- `files/.htaccess` and `files/apache-hardening.conf` get deployed to
  `/opt/easyappointments/config/` on the host, then bind-mounted
  **read-only** into the container (`/var/www/html/.htaccess`,
  `/etc/apache2/conf-enabled/zz-hardening.conf` — the latter as a plain
  file, not a symlink, which Apache's `conf-enabled/*.conf` glob doesn't
  care about). The image's own `docker-php.conf` already sets
  `AllowOverride All` on `/var/www/`, so the `.htaccess` just needs to
  exist — no other Apache config needs touching.
- `mod_rewrite` isn't enabled by default in this image, and its
  `docker-entrypoint.sh` takes no argument or environment variable to
  do so (checked the actual entrypoint script before reaching for this —
  there's no cleaner built-in hook to use instead). The compose file's
  `entrypoint:` override runs `a2enmod rewrite` before handing off to
  the original entrypoint. This runs on every container start;
  `a2enmod` is itself idempotent (a no-op if already enabled), so
  re-running the role/recreating the container doesn't fail or
  duplicate anything.
- `community.docker.docker_compose_v2`'s default `recreate: auto`
  already recreates a service when its compose definition changes
  (new volumes, new entrypoint) — same as plain `docker compose up -d`.
  No extra force-recreate step needed for this to take effect.

## Custom favicon (optional)

The upstream favicon isn't admin-UI configurable the way
`company_logo`/`company_color`/`theme` are (see "Pairing with Nextcloud
Calendar" above and the general settings note below — favicon is a
static file reference hardcoded in every layout template, not a
database-backed setting). Set `easyappointments_favicon_url` to fetch
and bind-mount a replacement over `/var/www/html/assets/img/favicon.ico`,
same read-only bind-mount mechanism as the Apache config above. Off by
default — the upstream icon is used if unset.

Deliberately fetched by URL (`ansible.builtin.get_url`) rather than
committed as a binary to this role's own `files/`: a branded icon is
homelab/deployment-specific content, not generic reusable boilerplate —
same reasoning as why domain names, secrets, and other deployment-
specific values live in your inventory repo's `group_vars`, not here.
`get_url`'s default `force: false` means it only downloads once, not on
every apply.

## Custom social card (optional)

Same mechanism as the favicon above, for the Open Graph preview image
(`og:image`) shown when the booking page URL is shared on social media
or in chat apps — hardcoded as `assets/img/social-card.png` in
`application/views/layouts/booking_layout.php`, not admin-UI
configurable. Set `easyappointments_social_card_url` to fetch and
bind-mount a replacement over
`/var/www/html/assets/img/social-card.png`. Off by default — the
upstream image is used if unset.

Unlike the favicon, `easyappointments_social_card_sha256` is required
whenever the URL is set (asserted at play time) and passed to
`get_url`'s `checksum` param — this asset is typically fetched from a
URL on the live public site rather than a private inventory host, so
the role verifies the fetched bytes match a pinned hash rather than
trusting whatever the URL returns at apply time. `get_url` only
re-fetches when the checksum no longer matches what's already on disk.

## First login

Easy!Appointments' first-run setup wizard (creates the admin account)
runs from the browser on first visit to `easyappointments_base_url`,
not from this role — there's no bootstrap-admin environment variable
like `authentik`'s. Visit the site after the role finishes and complete
the wizard.

## What this role does not do

- Doesn't create the CalDAV pairing with Nextcloud (or any other
  calendar) — per-provider admin-UI config, see above.
- Doesn't manage services/providers/business hours — all in-app admin
  UI configuration, out of scope for infrastructure-as-code the same
  way Authentik's per-application SSO client config is.
- Doesn't back up the MariaDB volume — point the `restic` role at
  `/var/lib/docker/volumes/easyappointments-db/_data` (or take a
  `mysqldump` on a schedule and back up the dump instead, which
  restores more predictably across MariaDB versions) if this instance
  matters enough to need disaster recovery, which — appointment/
  customer data — it almost certainly does.
