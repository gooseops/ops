#! /bin/bash

#TODO
# Add help/usage functions
# 4: Set storage pool
# 5: Determine if other vms have same name
#     - add warning that if other vms have same name, they will be destroyed

## Add coloring to errors and progress

while getopts ":hi:v:y" o; do
    case "${o}" in
        h) echo "help function";;
        i) declare start_vmid="${OPTARG}";; 
        v) echo "You are using ${OPTARG} for your boot disk on these vms";;
        y) declare -g mode_noninteractive=true ;; 
        *) echo "you broke this";;
    esac
done

if [ "${mode_noninteractive}" == true ]; then
    printf "\n\t\tWARNING: POTENTIAL DATA LOSS"
    printf "\n\tNon-interactive mode is potentially desctructive and should be"
    printf "\n\tused with caution.  Please run the script with the -h help flag"
    printf "\n\tin order to understand more about what the non-interactive mode"
    printf "\n\tdoes. Press Ctrl+c to abort now.  Sleeping 10 while waiting for"
    printf "\n\tabort.  After 10 seconds, continuing.\n"
    sleep 3
    declare waittime=0
    while [ ${waittime} -le 10 ]; do
        printf "\nSleeping...Press Ctrl+c to abort\n" ;
        sleep 1 ;
        let "waittime++" ;
    done
    printf "\nContinuing now with non-interactive mode.\n"
    sleep 2
fi

function packages_error {
    echo >&2 "ERROR: This script requires the package, ${package} , but it's not installed.  Please install ${package} and rerun.";
    exit 1;
}

function packages_check {
    echo "Verifying necessary packages..."
    sleep 2
    for package in "${packages[@]}"; do 
    type "${package}" >/dev/null 2>&1 || packages_error
    done
    echo "The required packages for running this script are installed."
    sleep 2
}

declare packages=( wget qm pvesm virt-customize )

packages_check

function set_start_vmid {
    echo "Determining currrent max VMID"
    sleep 2
    max_vmid=$(qm list | awk '{print $1;}' | sort -rn | head -1)
    declare max_vmid
    [[ -z "${max_vmid}" ]] && echo "There are currently no VMIDs" || echo "The current max VMID is: ${max_vmid}"
    sleep 2
    declare -g start_vmid=$(("${max_vmid}"+1000))
    echo "The starting non-conflicting vmid is: ${start_vmid}"
}

[[ -z "${start_vmid}" ]] && set_start_vmid || echo "Using commandline argument of ${start_vmid} as the starting vmid."

sleep 2

## Add warning for interactive mode and take user response

echo "Creating templates serially beginning at VMID: ${start_vmid}..."
sleep 2

declare images=(
    "ubuntu-focal-amd64,https://cloud-images.ubuntu.com/minimal/releases/focal/release/ubuntu-20.04-minimal-cloudimg-amd64.img"
    "ubuntu-jammy-amd64,https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img"
    "ubuntu-jammy-server-amd64,https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    "ubuntu-noble-amd64,https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"
    "debian-bullseye-amd64,https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
    "debian-bookworm-amd64,https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
)

function template_vmid_error {
    echo >&2 "ERROR: ${template_id} already exists, cannot continue."
    echo >&2 "Choose a higher starting vmid or delete the vms/templates"
    echo >&2 "that have vmids that conflict with your starting vmid."
}

function template_name_check  {
    while read -r vmid name ; do
        if [ "${template_name}" == "${name}" ]; then
            echo "VMID: ${vmid} NAME: ${name} is a conflict and must be destroyed."
            if [ "${mode_noninteractive}" == true ]; then
                echo "Destroying ${vmid} ${name}..."
                sleep 5
                qm destroy "${vmid}" --destroy-unreferenced-disks=1
            else
                echo "Do you wish to continue?" 
                echo "Enter 'y' for yes or 'n' for no."
                read -r input < /dev/tty
                if [ "${input}" == "y" ]; then
                    echo "Destroying ${vmid} ${name}..."
                    qm destroy "${vmid}" --destroy-unreferenced-disks=1
                elif [ "${input}" != "y" ]; then
                    echo "Cannot continue with naming conflicts"
                    exit 1
                fi
            fi
        fi
    done < <(qm list | awk 'NR>1{print $1 FS $2}')
}

function create_template {  
    
    wget -O /tmp/"${template_name}.qcow2" "${download_url}"
    virt-customize -a /tmp/"${template_name}.qcow2" --install qemu-guest-agent
    qm create "${template_id}" --name "${template_name}" --memory 512 --cores 1 --net0 virtio,bridge=vmbr0 || template_vmid_error
    qm importdisk "${template_id}" /tmp/"${template_name}.qcow2" local-lvm
    qm set "${template_id}" --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-"${template_id}"-disk-0 --boot c --bootdisk scsi0 --ide2 local-lvm:cloudinit --serial0 socket --vga serial0 --agent enabled=1
    qm template "${template_id}"
}

declare template_id="${start_vmid}"
for element in "${images[@]}"; do
    declare template_name="${element%,*}"
    declare download_url="${element#*,}"
    echo "Creating template VMID: ${template_id} NAME: ${template_name}..."
    sleep 2
    template_name_check
    create_template
    (( template_id++ ))
done
