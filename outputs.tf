output "vm_ips" {
  description = "Static address of each VM (the Ansible inventory uses the same values)."
  value       = local.vm_ips
}

output "ssh_commands" {
  description = "Ready-to-paste SSH commands."
  value       = { for name, ip in local.vm_ips : name => "ssh ${var.admin_user}@${ip}" }
}
