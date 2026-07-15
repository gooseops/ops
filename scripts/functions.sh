#!/usr/bin/env bash
# Helpers sourced by justfile recipes (and usable directly in a shell).
# Adapted from the maintainer's hivecraft-infra repo. Differences here:
#   - Doppler project is hardcoded to "ops" (the only project this repo
#     targets).
#   - Only one environment exists today: config slug "prod" (Doppler
#     config display name "Production"). The env plumbing still takes
#     an argument so a second environment can be added later without
#     touching the justfile.
#   - SSH key only, for now: no GCP service-account key or kubeconfig
#     pull. Add those following this same pattern once their Doppler
#     secret names are confirmed.

DOPPLER_PROJECT_NAME="ops"

# Ensure a symlink into a private, non-public repo exists at the given
# path in this repo. Leaves an already-valid symlink alone. Refuses to
# touch a path that exists and is a real (non-symlink) file/directory —
# that's either not this function's job or a sign something's wrong,
# so it errors out rather than guessing. Otherwise tries the given
# default target path; if that's not a directory, prompts the operator
# for the correct path on this machine. Warns (does not fail) if the
# resolved target isn't tracked inside a git working tree (it may be a
# subdirectory of a repo rather than a repo root, so this doesn't just
# check for a local .git).
# Usage:
#   f_ensureExternalLink <link-path> <default-target> <label>
function f_ensureExternalLink() {
    local _link="${1}"
    local _default="${2}"
    local _label="${3}"

    if [ -L "${_link}" ] && [ -e "${_link}" ]; then
        echo "OK: ${_link} -> $(readlink "${_link}")"
        return
    fi

    if [ -e "${_link}" ] && [ ! -L "${_link}" ]; then
        echo "ERROR: ${_link} exists and is a real file/directory, not a symlink. Resolve by hand." >&2
        return 1
    fi

    local _target="${_default}"
    if [ ! -d "${_target}" ]; then
        echo "${_label} not found at default path: ${_target}"
        read -r -p "Enter the correct path for ${_label}: " _target
        _target="${_target/#\~/${HOME}}"
    fi

    if [ ! -d "${_target}" ]; then
        echo "ERROR: ${_target} is not a directory." >&2
        return 1
    fi

    if ! git -C "${_target}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "WARNING: ${_target} is not inside a git working tree. Linking anyway." >&2
    fi

    rm -f "${_link}"
    mkdir -p "$(dirname "${_link}")"
    ln -s "${_target}" "${_link}"
    echo "Linked ${_link} -> ${_target}"
}

# Set up an environment for the first time: prompts for the Doppler
# token, writes .envs/.env.<env>, fetches the SSH key pair from Doppler
# into .keys/. By default prompts the operator at the end to activate
# the env immediately (so the common `just setup foo && just use foo`
# two-step collapses into a single command). The second argument
# controls that:
#   prompt  — ask (default; for interactive `just setup` calls)
#   always  — auto-activate without asking
#   never   — print the next step and exit (used by f_selectEnv below
#             to avoid a prompt loop when setup was invoked via
#             `just use` against an env that does not yet exist)
# Re-running clobbers any existing file.
# Usage:
#   f_setupEnv prod
#   f_setupEnv prod never
function f_setupEnv() {
    local _environment="${1}"
    local _autoActivate="${2:-prompt}"
    local _filename=".envs/.env.${_environment}"
    local _doppler_token

    [ -d ".keys" ] || mkdir ".keys"
    [ -d ".envs" ] || mkdir ".envs"

    : > "${_filename}"
    echo "Please enter your ${_environment} Doppler token: "
    read -rs _doppler_token
    {
        echo "DOPPLER_TOKEN=${_doppler_token}"
        echo "DOPPLER_CONFIG=${_environment}"
        echo "DOPPLER_PROJECT=${DOPPLER_PROJECT_NAME}"
        echo "TF_VAR_doppler_token=${_doppler_token}"
        # Homelab VMs get rebuilt/reinstalled often, so each host's SSH
        # key rotates too. There's no per-repo ansible.cfg to hold this
        # (removed — see CLAUDE.md), so it lives here instead.
        echo "ANSIBLE_HOST_KEY_CHECKING=False"
    } >> "${_filename}"

    # Export so the doppler CLI below can authenticate.
    export DOPPLER_TOKEN="${_doppler_token}"
    export DOPPLER_PROJECT="${DOPPLER_PROJECT_NAME}"
    export DOPPLER_CONFIG="${_environment}"

    doppler secrets get ANSIBLE_SSH_PRVKEY --plain > ".keys/${_environment}"
    chmod 0600 ".keys/${_environment}"
    doppler secrets get ANSIBLE_SSH_PUBKEY --plain > ".keys/${_environment}.pub"
    chmod 0644 ".keys/${_environment}.pub"

    echo "${_environment} setup is complete."

    case "${_autoActivate}" in
        always)
            f_selectEnv "${_environment}"
            ;;
        never)
            echo "Run 'just use ${_environment}' to activate."
            ;;
        prompt|*)
            local _answer
            read -r -p "Activate ${_environment} now? [Y/n] " _answer
            if [[ -z "${_answer}" || "${_answer}" =~ ^[Yy]$ ]]; then
                f_selectEnv "${_environment}"
            else
                echo "Run 'just use ${_environment}' to activate later."
            fi
            ;;
    esac
}

# Activate an environment: copies .envs/.env.<env> to the active
# .envs/.env, then sources the file so DOPPLER_TOKEN/CONFIG/PROJECT and
# TF_VAR_doppler_token are exported into the current shell. If the env
# file does not yet exist, delegates to f_setupEnv first so the
# missing-file check lives in exactly one place.
# Usage:
#   source scripts/functions.sh
#   f_selectEnv prod
function f_selectEnv() {
    local _environment="${1}"
    local _filename=".envs/.env.${_environment}"

    # If the env file is missing, run setup but suppress its "activate
    # now?" prompt — we are about to activate ourselves a few lines
    # below.
    [ -f "${_filename}" ] || f_setupEnv "${_environment}" never

    cp "${_filename}" ".envs/.env"
    set -a
    # shellcheck disable=SC1090
    source "${_filename}"
    set +a
    echo "Now using environment: ${_environment}"
}
