# restic role

Deploys [restic](https://restic.net) backups: one or more independent,
scheduled, retained, integrity-checked backup jobs per host, writing to
a repository you choose (an NFS-mounted path this role can optionally
mount for you, or anything else restic supports — SFTP, S3-compatible
object storage, etc., just by changing `repository`).

## What this role is (and isn't) for

Restic is a backup *engine* — encryption, content-deduplication,
point-in-time snapshots, retention policies, integrity verification.
That's a different job than a network filesystem: NFS gives you
somewhere to put bytes, not versioning or dedup or automated pruning.
This role assumes you already have a destination (NFS share, object
storage, whatever) and adds the actual backup discipline on top.

**Not every dataset benefits equally.** Small, frequently-changing,
genuinely-need-history data (database dumps, Terraform state,
application config/state exports) is exactly what restic is good at.
Large, mostly-static, replaceable content (a media library, say) pays
restic's chunking/dedup cost for very little benefit — either skip
backing it up through this role entirely, or handle it as a plain
secondary copy outside restic. This role doesn't care what you point it
at; deciding what's actually worth this treatment is a per-dataset call
each time you add a job.

## Design: independent jobs, not one flat backup

Each entry in `restic_jobs` is a fully independent unit — own
repository, own password, own paths, own retention, own schedule. Two
systemd timer pairs get created per job:

- `restic-backup-<name>.timer` → `restic-backup-<name>.service`: runs
  `restic backup` on the job's paths, then `restic forget --prune`
  against the job's retention settings. Default daily,
  `RandomizedDelaySec` staggers multiple jobs so they don't all hit the
  repository target at once.
- `restic-check-<name>.timer` → `restic-check-<name>.service`: runs
  `restic check` — verifies the repository itself isn't corrupted.
  Default weekly, deliberately separate from the backup run (a full
  check reads the whole repo, no reason to pay that cost daily on a
  homelab-scale dataset).

This role runs the first backup immediately at deploy time (not just
enables the timer and waits) and asserts a snapshot actually landed —
same "verify it for real, not just that the command exited 0" pattern
used elsewhere in this repo. If that assertion fails, the timer/service
files are still in place; fix whatever the failure points at and
re-run.

## NFS mount

Off by default (`restic_nfs_mount_enabled: false`) — this role doesn't
assume it owns your NFS mount if one already exists some other way.
Turn it on and it'll install `nfs-common` and mount
`restic_nfs_server:restic_nfs_export` at `restic_nfs_mount_path` via
`ansible.posix.mount` (already a dependency of this repo). Your jobs'
`repository` values then just need to live under that mount path.

## Doppler secrets checklist

Per job, in `restic_jobs[].password`: the repository's encryption
password. There's one of these **per job**, not one global secret —
losing a single job's password only costs you that job's history, not
every backup on the host. Source each through group_vars/host_vars,
never hardcoded in inventory, following the same
`lookup('ansible.builtin.env', ...)` pattern used elsewhere in this
repo's group_vars (the lookup itself lives in your inventory repo, not
in this role — see `defaults/main.yml`'s example).

**Write these passwords down somewhere durable outside the repo they
protect** (a password manager, not a note only saved next to the
backups themselves) — a lost restic repository password makes every
snapshot in that repository permanently unrecoverable. There's no reset
mechanism; that's the whole point of client-side encryption.

## What this role does not do

- Doesn't decide what to back up — that's a per-host, per-dataset
  decision made in your inventory repo's `restic_jobs`, not baked into
  this role.
- Doesn't handle offsite replication. Every job here writes to one
  repository; a same-LAN NFS target alone doesn't give you a second,
  independent copy outside this homelab's blast radius (fire, theft,
  a compromised host). Restic can target cloud object storage just as
  easily as a local path — adding a second, offsite job (or a second
  repository for the same data) is a natural follow-up, not implemented
  by default here.
- Doesn't restore anything. `restic restore`, `restic mount` (browse a
  snapshot as a filesystem), and friends are operator actions against
  the repository directly — no role wraps them, since a restore is a
  deliberate, supervised action, not something that should be
  automatable the same way a backup is.
