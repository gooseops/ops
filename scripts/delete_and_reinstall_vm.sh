#!/bin/bash

export _vmid

_vmid="${1}"

# shellcheck disable=SC2087
ssh 00 <<EOF
qm stop "${_vmid}"
qm destroy "${_vmid}" --destroy-unreferenced-disks --purge
EOF

if [[ -d ../terraform/worlds/proxmox/world-00 ]]; then
    cd ../terraform/worlds/proxmox/world-00 || echo "Directory doesn't exist."
    terraform apply -auto-approve
else
    echo "Directory doesn't exist"
    exit 1
fi