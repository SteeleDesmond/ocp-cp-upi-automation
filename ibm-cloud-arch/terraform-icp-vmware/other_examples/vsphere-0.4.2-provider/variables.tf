##### vSphere Access Credentials ######

variable "vsphere_user" { default = "___INSERT YOUR OWN____" }
variable "vsphere_password" { default = "___INSERT YOUR OWN____" }
variable "vsphere_server" {
  description = "IP Address or FQDN of vsphere server"
  default = "___INSERT YOUR OWN____"
}
variable "allow_unverified_ssl" {
  description = "If the vsphere api server uses self signed certificates for https traffic, set to true"
  default = "true"
}

##### vSphere deployment specifications ######
variable "vsphere_datacenter" { default = "___INSERT YOUR OWN____" }
variable "cluster" { default = "___INSERT YOUR OWN____"}
variable "resource_pool" {
  description = "Full path of resource pool. i.e. <cluster>/Resources/<pool name>"
  default = "___INSERT YOUR OWN____"
}
variable "network_label" { default = "___INSERT YOUR OWN____" }
variable "datastore" { default = "___INSERT YOUR OWN____" }
variable "template" {
  description = "VM template to provision servers from"
  default = "___INSERT YOUR OWN____"
}
variable "folder" {
  description = "VM Folder name. Later versions will provision all VMs to this folder"
  default = "ibmcloudprivate"
}

# Name of the ICP installation, will be used as basename for VMs
variable "instance_name" { default = "myicp" }

#################################
##### ICP Instance details ######
#################################
variable "master" {
  type = "map"

  default = {
    nodes  = "1"
    vcpu   = "8"
    memory = "16384"

    disk_size             = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size      = "100"   # Specify size for docker disk, default 100.
    datastore_disk_size   = "50"    # Specify size datastore directory, default 50.
    datastore_etcd_size   = "50"    # Specify size etcd datastore directory, default 50.
    thin_provisioned_etcd = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    thin_provisioned      = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub         = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove   = "false" # Set to 'true' to not delete a disk on removal.

    start_iprange = "" # Leave blank for DHCP, else masters will be allocated range starting from this address
  }
}

variable "proxy" {
  type = "map"

  default = {
    nodes  = "1"
    vcpu   = "2"
    memory = "4096"

    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.

    start_iprange = "" # Leave blank for DHCP, else proxies will be allocated range starting from this address
  }
}

variable "worker" {
  type = "map"

  default = {
    nodes  = "1"
    vcpu   = "4"
    memory = "16384"

    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.

    start_iprange = "" # Leave blank for DHCP, else workers will be allocated range starting from this address
  }
}

variable "management" {
  type = "map"

  default = {
    nodes  = "1"
    vcpu   = "8"
    memory = "16384"

    disk_size           = ""      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    log_disk_size       = "50"    # Specify size for /opt/ibm/cfc for log storage, default 50
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.

    start_iprange = "" # Leave blank for DHCP, else workers will be allocated range starting from this address
  }
}

# Username and password for the initial admin user
variable "icppassword" { default = "admin" }
