#!/bin/bash

# Cluster name is set by Terraform
echo ECS_CLUSTER='%ECS_CLUSTER_NAME%' >> /etc/ecs/ecs.config

function log {
    timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
    echo "${timestamp} $*"
}

function setup_nvme_storage {
    # Mount an NVMe volume to /var/lib/docker, if one is available. Will only mount the first one!
    #
    # This should be safe to do, the docker rpm only creates the /var/lib/docker directory, and doesn't
    # write anything to the directory until startup. User data is run by cloud-init before docker and ECS are started,
    # so mounting over /var/lib/docker should not cause problems.
    volume=$(lsblk -o NAME,MODEL | grep "Amazon EC2 NVMe Instance Storage" | head -1 | awk '{print $1}')
    if [ -z "$volume" ]
    then
        log "No NVMe storage found, skipping setup."
        return
    fi
    device="/dev/${volume}"

    log "NVMe storage found at ${device}, creating filesystem."
    mkfs -t xfs "${device}"

    log "Mounting NVMe storage to /var/lib/docker."
    if [ ! -d /var/lib/docker ]
    then
        mkdir -p /var/lib/docker
    fi
    mount "${device}" /var/lib/docker
    # match permissions set by the docker rpm
    chmod 710 /var/lib/docker

    # We don't typically reboot EC2 instances, but in case it does happen, add it to fstab, as user data scripts
    # are only run once at instance launch time.
    uuid=$(blkid "${device}" | awk '{print $2}' | sed 's/"//g')
    log "Mount complete, adding ${device} to fstab with UUID: ${uuid}."
    echo "${uuid} /var/lib/docker xfs defaults 0 2" >> /etc/fstab

    # Docker does not depend on cloud-init to finish to start, so it may (on some instance types)
    # already be running using /var/lib/docker on the root filesystem, which we just mounted over.
    # So we restart docker to make sure it uses the new mount.
    log "Restarting docker."
    systemctl restart docker
    log "Docker restarted."
}

# If we have NVMe storage, mount it to /var/lib/docker so that Docker will use it.
# Value of first element is set by Terraform, the generated version will look either like:
#   if [ "true" = "true" ]
# or
#   if [ "false" = "true" ]
# shellcheck disable=SC2050
if [ "%USE_NVME_STORAGE%" = "true" ]
then
    log "USE_NVME_STORAGE set to true, setting up NVMe storage."
    setup_nvme_storage
else
    log "USE_NVME_STORAGE set to not true, skipping NVMe setup."
fi
