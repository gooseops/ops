# postgresql role

Installs and configures a shared, single-node Postgres instance (native apt package,
not a container) used as the external database for this repo's other
app roles (e.g. authentik, odoo, synapse, vaultwarden, mattermost) via the
shared-external-DB pattern documented in each of their own `README.md`s
under "Prerequisites." This role does not know about any specific app;
it just provisions whatever superuser password, per-app roles,
databases, and `pg_hba.conf` entries you hand it via
`postgresql_superuser_password`/`postgresql_users`/
`postgresql_databases`/`postgresql_hba_entries`.

## Secrets

`postgresql_superuser_password` and every `postgresql_users[].userpass`
are required — the role asserts and fails loud if either is empty or if
the superuser password is still the literal placeholder default
(`"changethis"` in `defaults/main.yml`). Source real values through
group_vars/host_vars in your inventory repo, same convention as every
other role here — see `defaults/main.yml`'s comments.

## Decommissioning an app: move it to the `_absent` lists, don't just delete it

`community.postgresql.postgresql_pg_hba` (used for
`postgresql_hba_entries`), and `postgresql_user`/`postgresql_db` (used
for `postgresql_users`/`postgresql_databases`), only create/update what's
currently in those lists — they have no concept of "this entry used to
be here and isn't anymore." Deleting an app's block from those three
vars outright leaves its old database, role, and hba line in place on
the live host, stale — nothing about that deletion is visible to a
future run.

Instead, move the entry into the matching `postgresql_databases_absent`/
`postgresql_users_absent`/`postgresql_hba_entries_absent` list (empty by
default — see `defaults/main.yml`) and re-run the role. It'll drop the
database, remove the hba line, and drop the role, in that order (dropping
the database first is what lets the role actually be dropped — see the
task comments in `tasks/ubuntu-postgresql.yml`).

**One case this doesn't automate**: if a user owns grants/objects beyond
just its one database in `postgresql_databases`, `DROP ROLE` fails
loud (the module's `fail_on_user` default is `true`, deliberately not
overridden) rather than silently leaving the role in place. If you hit
that, clean it up manually first, then re-run:

```bash
# on the postgres host
sudo -u postgres psql -c "DROP OWNED BY <app_db_user>;"
```

## No TLS between Postgres and connecting app hosts

The role never touches `ssl_cert_file`/`ssl_key_file`/`ssl=on` in
`postgresql.conf` — Postgres's TLS support isn't configured at all, so
a `hostssl` entry in `postgresql_hba_entries` wouldn't actually work
without separately provisioning certs first. Connections from app hosts
across the LAN are plaintext unless you add that yourself. Tracked as
tech debt in this repo's `PLAN.md`.

## What this role does not do

- Doesn't know about or manage any specific application's schema/data —
  that's each app's own role/first-run behavior once it can reach its
  database.
- Doesn't prune stale users/databases/hba entries automatically just
  because they're deleted from `postgresql_databases`/`postgresql_users`/
  `postgresql_hba_entries` — see above for the `_absent`-list mechanism
  that does.
- Doesn't configure TLS — see above.
