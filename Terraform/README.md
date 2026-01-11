# Proxmox Terraform Auto-Deployment – Ubuntu 24.04 VMs

This Terraform project helps you **automatically create and configure Ubuntu 24.04 VMs** on Proxmox VE using cloud-init.

**Features:**
- Clones from a prepared Ubuntu 24.04 cloud-init template (VMID 9000)
- Static IP configuration
- Custom username + password
- Cloud-init vendor data with embedded scripts
- Automatic Docker installation (optional via script)
- Project environment variables injection from `.env` file
- Ready for deploying your applications

## Prerequisites

- Proxmox VE 8.x or 9.x node
- Terraform ≥ 1.5
- A prepared **Ubuntu 24.04 cloud-init template** (VMID 9000) — **required** (see section below)
- Network bridge `vmbr0` configured on Proxmox
- Storage with enough space (e.g. `local-lvm`, `local-zfs`, etc.)

### Required: Create Ubuntu 24.04 Cloud-Init Template (VMID 9000 – 20GB disk)

Your Terraform code clones VMID **9000**, so this template **must** exist first.

We use the official Ubuntu 24.04 server cloud image and resize it to **20GB** by default (filesystem auto-expands on first boot via cloud-init growpart).

Run these commands **on your Proxmox node** (as root) via SSH or shell:

```bash
# 1. Go to iso/cloudimg storage directory
cd /var/lib/vz/template/iso/

# 2. Download the latest Ubuntu 24.04 server cloud image
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# 3. Resize to 20GB (sparse file – actual usage grows as needed)
qemu-img resize noble-server-cloudimg-amd64.img 20G

# 4. (Strongly recommended) Install qemu-guest-agent for better Proxmox integration
apt update && apt install -y libguestfs-tools
virt-customize -a noble-server-cloudimg-amd64.img --install qemu-guest-agent

# 5. Create empty VM (VMID 9000)
qm create 9000 \
  --name ubuntu-24.04-cloud-template \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci \
  --ostype l26

# 6. Import disk (change 'local-lvm' to your VM storage if different)
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm --format qcow2

# 7. Attach imported disk
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0

# 8. Add cloud-init drive (critical!)
qm set 9000 --ide2 local-lvm:cloudinit

# 9. Set boot order
qm set 9000 --boot order=scsi0

# 10. (Recommended) Add serial console & guest agent
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# 11. Convert to template (VM becomes clonable only)
qm template 9000
```

**Important:**
- Replace `local-lvm` with your actual VM storage (`pvesm status` to check)
- After this step, VM 9000 appears as a **Template** in Proxmox UI

## Quick Start – Step by Step

### 1. Create API Token on Proxmox

1. Log in to Proxmox web interface
2. Go to **Datacenter → Permissions → API Tokens**
3. Click **Add**
4. Recommended: Use/create a dedicated user (e.g. `terraform@pve`)
5. Token ID: e.g. `terraform-deploy`
6. **Do NOT** enable "Privilege separation" for simple setups
7. Copy **Token ID** and **Secret** immediately

### 2. Assign Permissions to the Token

Minimal recommended (via CLI):

```bash
pveum user add terraform@pve --comment "Terraform automation"
pveum acl modify / --user terraform@pve@pve --role Administrator
# OR more restricted:
# pveum acl modify /vms --user terraform@pve@pve --role PVEVMAdmin
# pveum acl modify /storage/local-lvm --user terraform@pve@pve --role PVEDatastoreUser
# pveum acl modify /sdn --user terraform@pve@pve --role PVEAuditor
```

### 3. Prepare Terraform Configuration

1. Open the project folder in VS Code / your editor
2. Rename file:

   ```
   terraform.tfvars.sample  →  terraform.tfvars
   ```

3. Fill in your real values in `terraform.tfvars`:

   ```hcl
   # Proxmox API
   pve_api_url      = "https://192.168.1.55:8006/api2/json"      # ← your PVE IP
   pve_token_id     = "terraform-deploy"
   pve_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   pve_node         = "pve"                           # your node name

   # VM settings
   vm_id_start      = 20100
   vm_ip_address    = "192.168.1.201/24"              # free static IP
   vm_gateway       = "192.168.1.1"
   vm_dns_servers   = ["1.1.1.1", "8.8.8.8"]
   vm_username      = "adminuser"
   vm_password      = "your-very-secure-password"

   # Proxmox SSH (used for uploading cloud-init snippets)
   pve_ssh_username     = "root"                      # or your ssh user
   pve_ssh_password     = "your-pve-root-password"
   pve_ssh_node_address = "192.168.1.55"              # same as pve_api_url IP
   ```

### 4. Prepare Project Environment Variables (Optional)

If your scripts need env vars:

1. Go to folder `projectResource/`
2. Rename:

   ```
   .env.sample  →  .env
   ```

3. Edit `.env` with your values, example:

   ```env
   DATABASE_URL=postgresql://user:pass@db:5432/app
   API_KEY=sk-abcdefghijklmnopqrstuvwxyz
   TZ=America/Toronto
   ```

### 5. Deploy the VM

```bash
# Initialize (only needed first time)
terraform init

# Preview changes
terraform plan

# Create the VM
terraform apply
```

Type `yes` when prompted.

Wait 2–5 minutes → your new Ubuntu VM should be running and ready.

## Useful Commands

```bash
# Destroy the VM
terraform destroy

# Destroy specific VM (if count > 1)
terraform destroy -target=proxmox_virtual_environment_vm.ubuntu_vm[0]
```

## Folder Structure

```
.
├── main.tf                     # VM resource + clone config
├── provider.tf                 # Proxmox provider & SSH config
├── variables.tf                # Variable declarations
├── terraform.tfvars.sample     # ← rename & fill!
├── files.tf                    # Cloud-init vendor data + scripts embedding
├── scripts/
│   ├── cloud-init-vendor.yaml.tpl
│   ├── init.sh
│   ├── install-docker.sh
│   ├── runningProject.sh
│   └── ...
└── projectResource/
    └── .env.sample             # ← rename & fill for your project
```

## Recommendations & Notes

- **SSH Keys** → Uncomment `keys` line in `main.tf` and use public key instead of password
- **Insecure mode** (`insecure = true`) is enabled – use proper TLS in production
- **Multiple VMs** → Change `count = 1` in `main.tf` and adjust IP range logic if needed
- **Disk size** → Template starts at 20GB; resize cloned VM later with `qm resize <VMID> scsi0 +10G`
- **Storage** → If not using `local-lvm`, update `datastore_id` in `main.tf` and `files.tf`