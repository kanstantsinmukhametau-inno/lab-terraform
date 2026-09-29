resource "libvirt_network" "lab" {
  name      = var.network_name
  autostart = true

  forward = {
    mode = "nat"
  }

  # No DHCP range: every VM gets a static address from cloud-init network-config.
  ips = [
    {
      address = "${var.network_prefix}.1"
      netmask = "255.255.255.0"
    }
  ]
}
