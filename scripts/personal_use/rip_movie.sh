#!/bin/bash

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$log_file"
}


##################  BEGIN MAIN  ##################

# Define title
title=$(makemkvcon -r --directio=true info | grep DRV:0 | awk -F, '{print $6}' | sed 's/"//g')

# Define directory for ripped files
rip_dir="/mnt/linux_storage/jellyfin_rips/${title}"

# Define log file
log_file="${rip_dir}/rip_log.log"

# Exit if directory already exists. Useful if left unattended so 
# script won't keep running with same disc.
if [[ -d "${rip_dir}" ]]; then
    echo "Directory exists. Exiting..." >> "${log_file}"
    exit 0
else
    mkdir "${rip_dir}"
fi

# Create log file and confirm it is writable
touch "${log_file}" || { echo "Error: Cannot write to log file"; exit 1; }

# Log start time
log_message "Script started"

[[ -z "${title}" ]] && { echo "disc title not recognized"; exit 1; }

makemkvcon --minlength=1200 --decrypt --directio=true mkv disc:0 all "${rip_dir}" >> "${log_file}"

# Log end of rip
log_message "Rip completed"

for file in "${rip_dir}"/*.mkv; do
    HandBrakeCLI -Z "Fast 720p30" --audio-lang-list any --all-audio --subtitle-lang-list any --all-subtitles --subtitle-burned=none --subtitle-forced=eng -i "${file}" -o "${file%%.*}.mp4" >> "${log_file}"
    rm "${file}"
done

# Log end of rip
log_message "Encode completed"

# Set permissions on rip directory so not owned by root
chown -R stephen:stephen "${rip_dir}"

# Log end script
log_message "Script complete. Ejecting disc..."

eject /dev/sr0
