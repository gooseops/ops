# freebusy-sync role

Deploys `files/sync_freebusy_to_nextcloud.py` (this role's own script —
see its docstring for what it actually does: pulls free/busy blocks from
Google Calendar via a domain-wide-delegation service account and writes
generic "Busy" events into a Nextcloud calendar over CalDAV) as a
systemd service+timer pair. This role only covers deployment and
scheduling; the sync logic itself lives in the script, not here.

## Why this isn't a generic cron/task-runner role

Considered and rejected. This repo already schedules recurring work via
systemd timers, not cron (see `restic`) — a generic role would either
have to reinvent that per-job discipline (loud asserts on missing
required secrets, one timer pair per job) or lose it. `restic` already
shows what "generic" looks like at the right scope: a role that takes a
list of jobs, each with its own credential wiring. A single script
doesn't justify that abstraction yet — if a second, unrelated scheduled
script shows up later, that's the point to reconsider, not before.

## Why this runs on the Nextcloud host

The script's only real dependency is its CalDAV write target — Nextcloud
itself. Colocating means a localhost-adjacent write path and keeps
ownership of "the thing writing into Nextcloud's calendar" next to
Nextcloud. It intentionally does **not** run on `cloud_proxy` (the one
internet-facing host) — the Google service-account key this role
deploys has domain-wide delegation, a meaningfully sensitive credential,
and keeping it off the internet-facing host is worth more than any
convenience from being "already" reachable there.

## Prerequisites

1. **Google service account + domain-wide delegation.** See the script's
   own docstring and `files/.env.example` for the full setup
   (Cloud Console service account + JSON key, Workspace Admin console
   domain-wide delegation scoped to `calendar.readonly`). The downloaded
   key's full JSON content — not a path — goes into
   `freebusy_sync_google_service_account_key_json`; this role writes it
   to a file on the host itself and points the script at that path.
2. **Nextcloud CalDAV app password.** Generate a dedicated one under
   Nextcloud → Settings → Security → Devices & Sessions — never reuse
   the real account password. Same pattern used for the
   Easy!Appointments↔Nextcloud CalDAV pairing (see
   `homecloud-infra`'s `docs/runbooks/easyappointments-setup.md`).
3. **Secrets/identifiers.** `freebusy_sync_google_service_account_key_json`,
   `freebusy_sync_google_impersonate_subject`,
   `freebusy_sync_google_calendar_ids`, `freebusy_sync_nextcloud_base_url`,
   `freebusy_sync_nextcloud_calendar_url`,
   `freebusy_sync_nextcloud_username`,
   `freebusy_sync_nextcloud_app_password` are all required — the role
   asserts and fails loud if any are empty. All of these are routed
   through Doppler in `group_vars`/`host_vars`, not just the ones that
   are technically secrets — several identify a real person/account
   (the impersonated mailbox, the calendar IDs, the Nextcloud username)
   and are treated the same way for that reason.

## Manual testing

`files/sync_freebusy_to_nextcloud.py` is a normal standalone script —
nothing about it depends on Ansible. To dry-run it by hand before
trusting a deploy (recommended, see `homecloud-infra`'s
`docs/runbooks/freebusy-sync-google-setup.md` Step 9 for the full
walkthrough, including a couple of environment gotchas):

```bash
cd ansible/roles/freebusy-sync/files
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in by hand, same values as the Doppler secrets below
python3 sync_freebusy_to_nextcloud.py --dry-run --verbose
```

`.env`/`.venv/` here are gitignored (repo-wide `.env`/`.venv` patterns)
— safe to create and leave, or delete once satisfied.

## What this role does not do

- Doesn't create the Google service account, enable domain-wide
  delegation, or generate the Nextcloud app password — all manual,
  console-only steps (Google in particular: app-password-equivalent
  credentials for service accounts have no create API to automate
  against).
- Doesn't back up `sync_state.json` — losing it isn't destructive (the
  script just recreates busy blocks under fresh UIDs on the next run,
  orphaning the old ones server-side rather than corrupting anything),
  so it wasn't judged worth a dedicated `restic` job. Revisit if orphaned
  stale events in Nextcloud Calendar becomes an actual recurring
  annoyance.
