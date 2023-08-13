#!/bin/bash

#./create_ubuntu_lunar_template.sh <vm_id> <ubuntu_image_url> <memory_mb> <core_count>

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <vm_id> <ubuntu_image_url> <memory_mb> <core_count>"
    exit 1
fi

# Extract command-line arguments
vm_id="$1"
ubuntu_image_url="$2"
memory_mb="$3"
core_count="$4"

# Extract the filename from the URL
image_filename=$(basename "$ubuntu_image_url")
qcow2_filename="${image_filename%.img}.qcow2"

# Check if the .qcow2 file already exists
if [ -f "/root/$qcow2_filename" ]; then
    echo -e "\e[1;33m.qcow2 file already exists, skipping download and rename...\e[0m"
else
    # Check if the .img file already exists
    if [ -f "/root/$image_filename" ]; then
        echo -e "\e[1;33mImage file already exists, skipping download...\e[0m"
    else
        # Download the Ubuntu cloud image
        echo -e "\e[1;34mDownloading Ubuntu cloud image...\e[0m"
        wget "$ubuntu_image_url" -O "/root/$image_filename"
    fi

    # Rename the image file to qcow2 format
    mv "/root/$image_filename" "/root/$qcow2_filename"
fi

# Install qemu-guest-agent on the cloud image
echo -e "\e[1;34mInstalling qemu-guest-agent on the cloud image...\e[0m"
virt-customize -a "/root/$qcow2_filename" --install qemu-guest-agent

# Create a Proxmox VM with the modified cloud image
echo -e "\e[1;34mCreating Proxmox VM...\e[0m"
qm create "$vm_id" --name "ubuntu-lunar-cloudinit-template" --memory "$memory_mb" --cores "$core_count" --net0 virtio,bridge=vmbr0

# Import the modified cloud image as a disk
echo -e "\e[1;34mImporting modified cloud image as a disk...\e[0m"
qm importdisk "$vm_id" "/root/$qcow2_filename" local-lvm

# Attach the imported disk to the VM's SCSI controller
echo -e "\e[1;34mAttaching imported disk to VM's SCSI controller...\e[0m"
qm set "$vm_id" --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-"$vm_id"-disk-0

# Set the boot disk to the imported disk
echo -e "\e[1;34mSetting boot disk to the imported disk...\e[0m"
qm set "$vm_id" --boot c --bootdisk scsi0

# Attach a cloud-init ISO image for configuring the VM
echo -e "\e[1;34mAttaching cloud-init ISO image...\e[0m"
qm set "$vm_id" --ide2 local-lvm:cloudinit

# Enable serial console for the VM
echo -e "\e[1;34mEnabling serial console for the VM...\e[0m"
qm set "$vm_id" --serial0 socket --vga serial0

# Enable Proxmox agent for the VM
echo -e "\e[1;34mEnabling Proxmox agent for the VM...\e[0m"
qm set "$vm_id" --agent enabled=1

# Create a Proxmox template from the VM
echo -e "\e[1;34mCreating Proxmox template from the VM...\e[0m"
qm template "$vm_id"

echo -e "\e[1;32mScript completed!\e[0m"
