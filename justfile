# gooseops ops command runner.
# Run `just --list` (or just `just`) to see all recipes.
#
# Workflow on a fresh checkout:
#   nix develop            # enter the toolchain shell
#   just link-externals    # symlink in the inventory + terraform worlds repos
#   just deps              # install Ansible Galaxy collection deps
#   just use prod          # set up Doppler env + fetch SSH keys
#   just deploy base       # run the universal-host playbook
#
# This repo targets Proxmox today (an eventual move to Incus is
# planned but not yet underway). Two directories here are symlinks
# into a separate, non-public repo (homecloud-infra), kept out of this
# public repo on purpose:
#   ansible/inventory -> ~/github/homecloud-infra/ansible/inventory
#   terraform/worlds   -> ~/github/homecloud-infra/worlds
# The whole worlds/ directory is linked as one unit (not per-world) so
# a future staging/development world just shows up under
# terraform/worlds/<name> with no justfile change needed.
# `just link-externals` (re)creates both symlinks, prompting for the
# correct path on this machine if either isn't at its default location.

set dotenv-load
set dotenv-filename := ".envs/.env"
set dotenv-override

# Default terraform world (terraform/worlds/<world>). Override per
# recipe call once a second world exists, e.g. `just tf-plan world=staging`.
default_world := "production"

default:
    @just --list --unsorted

# --- Setup --------------------------------------------------------------

# (Re)create the two symlinks into the private, non-public homecloud-infra
# repo that this repo deliberately does not track: ansible/inventory and
# terraform/worlds. Tries each default path first; if a default isn't
# found, prompts for the correct path on this machine. Leaves an
# existing valid symlink alone. Refuses to touch a path that exists and
# is a real (non-symlink) file or directory — resolve that by hand.
link-externals:
    #!/usr/bin/env bash
    set -euo pipefail
    source scripts/functions.sh
    f_ensureExternalLink "ansible/inventory" "${HOME}/github/homecloud-infra/ansible/inventory" "Ansible inventory directory"
    f_ensureExternalLink "terraform/worlds" "${HOME}/github/homecloud-infra/worlds" "Terraform worlds directory"

# Install Ansible Galaxy collection dependencies (community.general,
# community.docker, community.postgresql, ansible.posix).
deps:
    ansible-galaxy collection install -r ansible/requirements.yml

# Set up an environment: prompts for Doppler token, writes
# .envs/.env.<env>, fetches the SSH key pair from Doppler into .keys/.
# By default asks at the end whether to activate the env immediately.
# Pass a second positional argument to skip the prompt:
#   just setup prod            # interactive prompt
#   just setup prod switch     # activate without asking
#   just setup prod no-switch  # do not activate (old behavior)
# Re-running clobbers any existing file for that env.
setup env="prod" mode="":
    #!/usr/bin/env bash
    set -euo pipefail
    source scripts/functions.sh
    case "{{mode}}" in
        switch)    f_setupEnv {{env}} always ;;
        no-switch) f_setupEnv {{env}} never  ;;
        "")        f_setupEnv {{env}} prompt ;;
        *)
            echo "Unknown mode '{{mode}}'. Use 'switch' or 'no-switch'." >&2
            exit 1
            ;;
    esac

# Activate an environment. Runs setup first if no env file exists yet.
use env="prod":
    #!/usr/bin/env bash
    set -euo pipefail
    source scripts/functions.sh
    f_selectEnv {{env}}

# Wipe local environment state (.envs/, .keys/). Useful before handing
# off a workstation or after a credential rotation.
cleanup:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf .envs .keys

# --- Lint and format ----------------------------------------------------

# Lint Terraform, Ansible, and shell scripts.
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    terraform -chdir=terraform fmt -check -recursive
    tflint --chdir=terraform --recursive
    ansible-lint ansible/
    shellcheck scripts/*.sh

# Format Terraform and Ansible files in place.
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    terraform -chdir=terraform fmt -recursive
    ansible-lint ansible/ --fix

# --- Ansible inventory --------------------------------------------------

# List the Ansible inventory.
inventory:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    ansible-inventory -i inventory/homelab.ini --list

# Render the inventory as a tree.
inventory-graph:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    ansible-inventory -i inventory/homelab.ini --graph

# List discoverable playbooks (anything matching *.playbook.yml).
playbook-list:
    @ls ansible/*.playbook.yml | xargs -n1 basename | sed 's/\.playbook\.yml$//'

# List all inventory group names (e.g. nextcloud, penpot, wireguard).
# Matches the form `just ssh <group>` accepts.
list-groups:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    ansible-inventory -i inventory/homelab.ini --list | jq -r 'keys[] | select(. != "_meta" and . != "all")' | sort

# List all inventory host IPs.
list-hosts:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    ansible-inventory -i inventory/homelab.ini --list | jq -r '._meta.hostvars | keys[]' | sort

# --- Ansible playbooks --------------------------------------------------

# Dry-run an Ansible playbook (--check --diff). Optional host=<inventory-name>.
# Defaults to the noop playbook (connectivity check) against all hosts.
# Examples:
#   just check base
#   just check nextcloud host=192.168.1.113
check playbook="noop" host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    doppler run --command 'ansible-playbook \
      -i inventory/homelab.ini \
      --check --diff --limit {{host}} \
      {{playbook}}.playbook.yml'

# Run an Ansible playbook for real. Optional host=<inventory-name> and
# optional tags=<comma-separated>.
# Defaults to the noop playbook (connectivity check) against all hosts.
deploy playbook="noop" host="all" tags="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    tag_args=""
    [ -n "{{tags}}" ] && tag_args="--tags {{tags}}"
    doppler run --command "ansible-playbook \
      -i inventory/homelab.ini \
      --limit {{host}} \
      $tag_args \
      {{playbook}}.playbook.yml"

# Same as deploy but with --ask-become-pass for the first run on a host
# whose admin password is not yet locked.
deploy-bootstrap playbook="noop" host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    doppler run --command 'ansible-playbook \
      -i inventory/homelab.ini \
      --ask-become-pass --limit {{host}} \
      {{playbook}}.playbook.yml'

# Block until every host in <host> responds to a full SSH handshake.
# Uses Ansible's wait_for_connection so the SSH config (key, user)
# matches every other recipe. Useful right after `just tf-apply`
# when a fresh VM is still finishing cloud-init.
#
# Examples:
#   just wait-ssh nextcloud
#   just wait-ssh 192.168.1.113
#   just wait-ssh all 600   # extend per-host timeout
wait-ssh host="all" timeout="300":
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    doppler run --command 'ansible \
      -i inventory/homelab.ini \
      --limit {{host}} \
      -m wait_for_connection \
      -a "timeout={{timeout}} sleep=5" \
      all'

# SSH into a host by inventory group name (e.g. nextcloud, penpot).
# The group must resolve to exactly one host IP; groups with multiple
# hosts (local_vms, llm, wireguard, ...) are rejected as ambiguous —
# ssh by IP directly instead, e.g. `just ssh 192.168.1.113`.
#
# User and key come from the same source ansible-playbook uses (see
# group_vars/all.yml): ANSIBLE_USER from Doppler, key at
# .keys/${DOPPLER_CONFIG}. Requires `just use <env>` to have been run
# this session.
ssh host:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible
    hv=$(ansible-inventory -i inventory/homelab.ini --list)
    ips=$(echo "$hv" | jq -r --arg h "{{host}}" '.[$h].hosts[]? // empty')
    n=$(echo -n "$ips" | grep -c . || true)
    if [ "$n" -eq 0 ]; then
      echo "no inventory group named '{{host}}'; run 'just list-groups'" >&2
      exit 1
    elif [ "$n" -gt 1 ]; then
      echo "'{{host}}' is ambiguous; candidates:" >&2
      echo "$ips" >&2
      exit 1
    fi
    ip="$ips"
    user=$(doppler secrets get ANSIBLE_USER --plain)
    echo "{{host}} -> $ip (key: .keys/${DOPPLER_CONFIG})"
    ssh -i "../.keys/${DOPPLER_CONFIG}" "${user}@${ip}"

# --- Terraform (per-world) ----------------------------------------------

# Initialize a terraform world. Reads the per-world config.local.tfbackend
# file to locate the state file.
tf-init world=default_world:
    #!/usr/bin/env bash
    set -euo pipefail
    cd terraform/worlds/{{world}}
    [ -f config.local.tfbackend ] || { echo "missing config.local.tfbackend in terraform/worlds/{{world}}" >&2; exit 1; }
    terraform init -backend-config=config.local.tfbackend

# Refresh providers and modules.
tf-init-upgrade world=default_world:
    #!/usr/bin/env bash
    set -euo pipefail
    cd terraform/worlds/{{world}}
    [ -f config.local.tfbackend ] || { echo "missing config.local.tfbackend in terraform/worlds/{{world}}" >&2; exit 1; }
    terraform init -upgrade -backend-config=config.local.tfbackend

# Show the current state's outputs.
tf-output world=default_world:
    #!/usr/bin/env bash
    set -euo pipefail
    cd terraform/worlds/{{world}}
    doppler run --command 'terraform output'

# Plan changes against a world.
tf-plan world=default_world:
    #!/usr/bin/env bash
    set -euo pipefail
    cd terraform/worlds/{{world}}
    doppler run --command 'terraform plan'

# Apply changes to a world (will prompt before applying).
tf-apply world=default_world:
    #!/usr/bin/env bash
    set -euo pipefail
    cd terraform/worlds/{{world}}
    doppler run --command 'terraform apply'

# Destroy a world's resources (will prompt).
tf-destroy world=default_world:
    #!/usr/bin/env bash
    set -euo pipefail
    cd terraform/worlds/{{world}}
    doppler run --command 'terraform destroy'

# Validate a world's config (requires tf-init first).
tf-validate world=default_world:
    #!/usr/bin/env bash
    set -euo pipefail
    cd terraform/worlds/{{world}}
    terraform validate
