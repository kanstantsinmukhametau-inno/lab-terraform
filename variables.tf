variable "libvirt_uri" {
  description = "libvirt connection URI."
  type        = string
  default     = "qemu:///system"
}

variable "pool" {
  description = "Existing libvirt storage pool for base image, disks and cloud-init ISOs."
  type        = string
  default     = "default"
}

variable "base_image_url" {
  description = "Ubuntu cloud image (URL or local path) used as the shared backing store."
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "network_name" {
  description = "Name of the libvirt NAT network created for the lab."
  type        = string
  default     = "lab"
}

variable "network_prefix" {
  description = "First three octets of the lab /24 network; .1 is the host gateway."
  type        = string
  default     = "192.168.150"
}

variable "admin_user" {
  description = "Login user created by cloud-init on every VM."
  type        = string
  default     = "lab"
}

variable "ssh_public_key_path" {
  description = "Public key authorised for admin_user."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vms" {
  description = "VMs to create: host octet, vCPUs, memory (MiB) and disk size (GiB)."
  type = map(object({
    ip_octet  = number
    vcpu      = number
    memory    = number
    disk_size = number
  }))
  default = {
    "nginx-vm"          = { ip_octet = 10, vcpu = 2, memory = 2048, disk_size = 15 }
    "k3s-control-plane" = { ip_octet = 11, vcpu = 2, memory = 4096, disk_size = 25 }
    "k3s-worker1"       = { ip_octet = 12, vcpu = 2, memory = 4096, disk_size = 25 }
    "k3s-worker2"       = { ip_octet = 13, vcpu = 2, memory = 4096, disk_size = 25 }
  }
}
