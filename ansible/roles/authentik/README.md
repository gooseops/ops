# authentik role

Deploys [Authentik](https://goauthentik.io) (SSO / identity provider) via
Docker Compose: a server container, a worker container, and a bundled
Redis instance. Fronted by this repo's existing `nginx-proxy` role for
TLS — same shape as `vaultwarden` and `nextcloud`.

## Why this isn't a port of hivecraft-infra's `authentik` role

The maintainer's other repo (`hivecraft-infra`) also has an `authentik`
role, but it deploys via Helm onto a Kubernetes cluster — appropriate
there because that repo already runs Kubernetes for its application
tier. This repo's homelab doesn't run Kubernetes for internal services
(the `kubernetes/manifests`/`helm/` directories here are for client
cloud-K8s engagements, not the homelab) — services here are plain
Docker Compose stacks on individual VMs, same as every other app role in
`ansible/roles/`. So this role is a fresh build following *this* repo's
established conventions, not a port. The two things carried over
directly from hivecraft-infra's version: pointing at an external,
already-running Postgres rather than bundling one (matches this repo's
own shared-`postgresql`-role pattern anyway), and bundling a
no-persistence Redis instance in the same compose stack rather than a
separate role (Authentik needs it for caching/Celery, and losing it on
restart is an acceptable trade-off — see `defaults/main.yml`).

## Prerequisites

1. **Postgres.** This role does not create a database. Run the shared
   `postgresql` role against your DB host with an `authentik` entry
   added to `postgresql_databases`/`postgresql_users`/
   `postgresql_hba_entries` (in your inventory repo's
   `group_vars/postgresql.yml`) — the same pattern `synapse`,
   `vaultwarden`, `mattermost`, and `odoo` already use. Then point
   `authentik_postgres_host`/`authentik_postgres_password` (and the
   rest, if you didn't use the defaults) at it.
2. **Secrets.** `authentik_secret_key`, `authentik_postgres_password`,
   `authentik_bootstrap_password`, `authentik_bootstrap_token` are all
   required — the role asserts and fails loud if any are empty. Source
   them through group_vars/host_vars, never hardcode them here.
3. **Reverse proxy.** This role only publishes plain HTTP on
   `authentik_http_port` (default `9000`) — TLS termination and the
   public hostname are the `nginx-proxy` role's job, configured via
   `nginx_proxy_configs` the same way every other app in this repo is
   fronted.

## First login

The bootstrap admin account is `akadmin`, password
`authentik_bootstrap_password`. Log in and either change that password
or set up your own admin identity, same as any fresh Authentik install.

## What this role does not do

Per-application SSO client config — OAuth2/OIDC providers,
applications, enrollment flows for the other services you want behind
Authentik — is out of scope. Wire those up through Authentik's own
admin UI/API once the service is up, or (if you want that config as
IaC) the Terraform Authentik provider, same separation of concerns
hivecraft-infra's version uses (see its ADR 020) — just not implemented
here, since it's inherently per-application and per-deployment, not
generic boilerplate.

## Object storage for media (optional)

Off by default — Authentik's local-disk volume is a fine default for a
homelab-scale instance. Set `authentik_s3_enabled: true` plus the
`authentik_s3_*` vars to point branding/media storage at any
S3-compatible bucket instead.
