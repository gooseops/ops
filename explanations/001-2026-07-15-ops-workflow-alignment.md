# Session One: Bringing Ops in Line with Hivecraft Infrastructure

## Overview

This session brought the command runner and operator workflow in the
ops repository into alignment with the conventions already proven out
in the maintainer's other infrastructure repository, Hivecraft
Infrastructure. Along the way, two previously separate and loosely
managed directories, one for Terraform worlds and one for the Ansible
inventory, were consolidated by the maintainer into a single private
repository called Homecloud Infrastructure, and this session's tooling
was updated to follow that consolidation. The session also introduced
a proper administrator user bootstrap and Secure Shell hardening role,
pulled over a connectivity check playbook, and corrected a variable
sourcing mistake along the way.

## Why This Exists

The maintainer runs several infrastructure repositories with similar
shapes but drifting conventions. Ops is a public, general purpose
repository covering homelab services on Proxmox plus reusable modules
for client engagements, while Hivecraft Infrastructure is a private,
single purpose production repository already running on a more mature
toolchain. The goal this session was to bring ops's command runner,
its guidance file for the coding assistant, and its plan document up
to the same standard, while being honest about where ops's situation
genuinely differs, rather than blindly copying everything over.

## Technical Decisions

Terraform was deliberately kept instead of migrating to Open Tofu, even
though Hivecraft Infrastructure already made that switch. The reasoning
volunteered by the maintainer was that Terraform as a keyword still
carries more resume and hiring recognition than Open Tofu, and since
this is a public portfolio repository, that visibility matters more
than internal consistency between two personal projects. The command
runner's infrastructure recipes were still renamed to a generic prefix
rather than one implying either tool by name, so the naming itself
stays tool agnostic even though the actual program invoked is Terraform.

The two previously separate directories for Terraform worlds and the
Ansible inventory were consolidated by the maintainer into the single
private Homecloud Infrastructure repository, with the single Terraform
world renamed from a numbered placeholder to a name reflecting that it
is now considered a production environment. The command runner's setup
recipe was changed to link the entire worlds directory as one unit,
rather than linking one world at a time, so that a future staging or
development environment will appear automatically without any further
changes to the command runner.

A discrepancy was found and resolved between two different Secure
Shell keys being used to reach the same fleet of hosts: one hardcoded
in a configuration file, and a second one sourced from the secrets
manager and used only by the convenience login recipe. The fix mirrors
Hivecraft Infrastructure's approach exactly: there is no longer any
Ansible configuration file at all in this repository. Instead, the
remote user and the private key path are both declared as inventory
variables that resolve at play time from the secrets manager's injected
environment, so every tool now authenticates with the exact same key
and user.

A new role was built to bootstrap the administrator account and harden
Secure Shell access, again mirroring the layered, deliberately ordered
approach used in Hivecraft Infrastructure: ensure the account exists,
install its authorized key, grant it passwordless sudo, lock its
password so only key based authentication remains possible, and only
then harden the Secure Shell daemon itself, specifically in that order,
because hardening first would risk a lockout if an earlier step had
gone wrong. One deliberate difference from the other repository's
version of this role is that the administrator's public key is sourced
live from the secrets manager rather than from a public key file
committed into the role, since the secrets manager was already the
single source of truth for that key pair here.

That introduced a mistake that was caught and corrected before the
session ended: the lookup of the public key from the environment was
initially written directly inside the role's task list, which violates
a standing convention that any lookup of an environment variable must
happen only in the inventory's group or host variable files, never
inline in tasks. The fix declared an empty, meaningless placeholder in
the role's defaults file, moved the actual environment lookup into the
inventory's shared variables file, and left the task list referencing
only the plain variable name, with an assertion that fails loudly if
the variable is still empty when the play runs.

A connectivity check playbook was pulled over verbatim from Hivecraft
Infrastructure, since it makes no assumptions specific to that
repository's naming scheme. Because the administrator bootstrap role
now actually changes system state, the command runner's default
playbook for its dry run, deploy, and bootstrap recipes was switched
back to this connectivity check playbook, rather than defaulting to the
role that changes state, so that running those recipes with no
arguments against every host is safe rather than surprising.

Finally, the maintainer asked whether ops needed the same numbered
architectural decision record system used in Hivecraft Infrastructure.
The conclusion was no: that system earns its value when a small number
of interlocking decisions compound across one tightly coupled system,
which describes the other repository's production build, but not this
one's grab bag of mostly independent homelab services and reusable
modules. The plan document already captures the reasoning behind the
handful of real decisions made here, inline, without needing a separate
numbered filing system.

## Dependencies

Three secrets were added to the secrets manager's configuration for
this repository during the session: the administrator username, and
the private and public halves of the Secure Shell key pair already
trusted on the existing fleet. The private Homecloud Infrastructure
repository is now the sole source for both the Terraform world contents
and the Ansible inventory contents, linked into this repository purely
through local symlinks that carry no reference inside this repository's
own version control.

## How It Fits Together

A fresh checkout now follows a specific order: enter the pinned
development shell, run the recipe that links in the two private
directories from the console infrastructure repository, install the
Ansible collection dependencies, then activate the environment, which
prompts for a secrets manager token and pulls down the Secure Shell key
pair. From that point forward, every command that touches secrets is
wrapped automatically, every Ansible command passes its inventory path
explicitly rather than relying on a configuration file, and the
development shell itself now sources the active environment file
directly, with a helper function available to reload it after
switching environments, matching the other repository's convenience.

## Gotchas

Two standing preferences were reinforced this session and are worth
repeating. First, the maintainer's system Secure Shell directory must
never be read by the assistant, even for public key material that
is not inherently sensitive; if key material is needed, it should
already be in the secrets manager or supplied directly. Second, the
maintainer runs every git command personally, including read only ones
like checking status or a remote's address, so the assistant's role is
to explain the exact commands to run, never to run them.

On the infrastructure side, the new administrator bootstrap role
replaces whatever is currently authorized for that account outright
rather than adding to it, so the secrets manager's stored key pair must
already match the key trusted on the existing hosts before this role is
ever applied for real, or the maintainer would lock themselves out.
Nothing in this session actually applied that role to a real host; it
was only verified through syntax checking, static analysis, and a safe
local connection check that does not touch any real machine.

The host key checking behavior was deliberately kept different from
Hivecraft Infrastructure: because homelab virtual machines here get
rebuilt and reinstalled often, strict host key checking was kept
disabled globally through the active environment file, rather than
adopting the other repository's stricter default, which only makes an
exception for a single ephemeral cloud edge host.

## What's Next

The plan document now tracks several deferred items for a future
focused session: adding a scoped configuration for the Ansible linter
so that its check passes cleanly against today's reality instead of
always failing against long standing findings, and reconsidering
whether the deploy and check recipes should require an explicit host
rather than defaulting to every host, given that the inventory itself
still needs an audit to separate live services from decommissioned or
outdated ones. Separately, and unrelated to this session's workflow
work, an Odoo service is in progress on its own branch, blocked on an
unresolved package dependency chain encountered during a manual
installation walkthrough.
