locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  gateway        = "${var.network_prefix}.1"
  vm_ips         = { for name, vm in var.vms : name => "${var.network_prefix}.${vm.ip_octet}" }
}

resource "libvirt_volume" "base" {
  name = "lab-ubuntu-noble-base.qcow2"
  pool = var.pool
  target = {
    format = { type = "qcow2" }
  }
  create = {
    content = { url = var.base_image_url }
  }
}

resource "libvirt_volume" "disk" {
  for_each = var.vms

  name     = "lab-${each.key}.qcow2"
  pool     = var.pool
  capacity = each.value.disk_size * 1024 * 1024 * 1024
  target = {
    format = { type = "qcow2" }
  }
  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
}

resource "libvirt_cloudinit_disk" "init" {
  for_each = var.vms

  name = "lab-${each.key}-cloudinit"
  user_data = templatefile("${path.module}/cloud-init/user-data.tftpl", {
    hostname       = each.key
    admin_user     = var.admin_user
    ssh_public_key = local.ssh_public_key
  })
  meta_data = yamlencode({
    instance-id    = "lab-${each.key}"
    local-hostname = each.key
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.tftpl", {
    address = local.vm_ips[each.key]
    gateway = local.gateway
  })
}

resource "libvirt_volume" "cloudinit" {
  for_each = var.vms

  name = "lab-${each.key}-cloudinit.iso"
  pool = var.pool
  create = {
    content = { url = libvirt_cloudinit_disk.init[each.key].path }
  }
}

resource "libvirt_domain" "vm" {
  for_each = var.vms

  name        = each.key
  type        = "kvm"
  vcpu        = each.value.vcpu
  memory      = each.value.memory
  memory_unit = "MiB"
  running     = true
  autostart   = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  # libvirt's default CPU model (qemu64) lacks SSE4.2/POPCNT, i.e. x86-64-v2; common
  # prebuilt native modules (sharp/libvips in sample-app) refuse to load without it.
  cpu = {
    mode = "host-passthrough"
  }

  devices = {
    disks = [
      {
        # Both disks use file-type sources: with type='volume' Ubuntu's virt-aa-helper
        # leaves the backing image and the cloud-init ISO out of the domain's AppArmor
        # profile, and QEMU fails with "Permission denied".
        source = {
          file = { file = libvirt_volume.disk[each.key].path }
        }
        target = { bus = "virtio", dev = "vda" }
        driver = { type = "qcow2" }
      },
      {
        device = "cdrom"
        source = {
          file = { file = libvirt_volume.cloudinit[each.key].path }
        }
        target = { bus = "sata", dev = "sda" }
      }
    ]

    interfaces = [
      {
        type  = "network"
        model = { type = "virtio" }
        source = {
          network = { network = libvirt_network.lab.name }
        }
      }
    ]

    graphics = [
      {
        vnc = { auto_port = true, listen = "127.0.0.1" }
      }
    ]
  }
}
