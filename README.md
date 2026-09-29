# lab-terraform

Four Ubuntu 24.04 VMs on local KVM/libvirt for the lab k3s + Knative platform.

| VM | IP | vCPU / RAM / disk | Role |
|---|---|---|---|
| nginx-vm | 192.168.150.10 | 2 / 2 GiB / 15 GB | TLS edge (nginx) + self-hosted GitHub runner |
| k3s-control-plane | 192.168.150.11 | 2 / 4 GiB / 25 GB | k3s server |
| k3s-worker1 | 192.168.150.12 | 2 / 4 GiB / 25 GB | k3s agent |
| k3s-worker2 | 192.168.150.13 | 2 / 4 GiB / 25 GB | k3s agent |

What it creates:
- a NAT network `lab` (192.168.150.0/24, gateway .1, no DHCP);
- one shared cloud-image base volume and a qcow2 overlay per VM, in pool `default`;
- per-VM cloud-init: user `lab` with your SSH key, passwordless sudo, qemu-guest-agent, static IP.

Provisioning (k3s, Knative, nginx, runner) lives in the separate `lab-ansible` repo.

## Requirements
- KVM + libvirt (`qemu:///system`), your user in the `libvirt` group.
- Terraform >= 1.6 (OpenTofu works with the same code).
  Ubuntu install:
  ```bash
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform
  ```
- An SSH key pair (default `~/.ssh/id_ed25519.pub`).

## Usage
```bash
terraform init
terraform plan
terraform apply
terraform output vm_ips
ssh lab@192.168.150.11      # cloud-init takes ~1-2 min after boot
```
Destroy everything: `terraform destroy`.

## Notes
- Sizes and addresses live in `var.vms`; the `lab-ansible` inventory uses the same static IPs.
- The provider is `dmacvicar/libvirt` 0.9.x, which uses the new nested schema. 0.8.x examples don't apply.
- A VNC console per VM listens on 127.0.0.1 (`virsh -c qemu:///system domdisplay <vm>`).
- Disks are attached as **file** sources. With `type='volume'` sources, Ubuntu's AppArmor helper
  (`virt-aa-helper`) leaves the backing image and the cloud-init ISO out of the VM profile, and QEMU
  fails with "Permission denied".
- CPU mode is **host-passthrough**. libvirt's default `qemu64` model lacks x86-64-v2 (SSE4.2/POPCNT),
  and prebuilt native modules such as sharp/libvips refuse to load without it.
- cloud-init manages `/etc/hosts`, so `lab-ansible` writes its entries into
  `/etc/cloud/templates/hosts.debian.tmpl` too, to survive reboots.
