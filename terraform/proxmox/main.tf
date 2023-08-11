variable "cloudinit_template_name" {
    type = string 
}

variable "proxmox_node" {
    type = string
}

variable "ssh_key" {
  type = string 
  sensitive = true
}

resource "proxmox_vm_qemu" "k8s-1" {
  count = 1
  name = "k3s-server-${count.index + 1}"
  target_node = var.proxmox_node
  clone = var.cloudinit_template_name
  agent = 1
  os_type = "cloud-init"
  cores = 4
  sockets = 1
  cpu = "host"
  memory = 4096
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot = 0
    size = "40G"
    type = "scsi"
    storage = "local-lvm"
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }
  
#   lifecycle {
#     ignore_changes = [
#       network,
#     ]
#   }

  # (Optional) Default User
  ciuser = "serveradmin"
  cipassword = var.cipassword

#   ipconfig0   = "ip=dhcp"

  ipconfig0 = "ip=10.27.27.10${count.index + 1}/24,gw=10.27.0.1"
#   nameserver = "172.20.0.31"
  
  sshkeys = <<EOF
  ${var.ssh_key}
  EOF

}















