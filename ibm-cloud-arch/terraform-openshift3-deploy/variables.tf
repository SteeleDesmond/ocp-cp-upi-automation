variable "bastion_ip_address" {
  default = ""
}
variable "bastion_ssh_user" {
  default = ""
}

variable "bastion_ssh_password" {
  default = ""
}
variable "bastion_ssh_private_key" {
  default = ""
}

variable "ssh_user" {
  default = "root"
}

variable "ssh_private_key" {
  default = ""
}

variable "ssh_password" {
  default = ""
}

variable "node_count" {
  default = 0
}

variable "master_count" {
  default = 0
}

variable "infra_count" {
  default = 0
}

variable "worker_count" {
  default = 0
}

variable "storage_count" {
  default = 0
}


variable "master_private_ip"  { type = "list" }
variable "infra_private_ip"   { type = "list" }
variable "worker_private_ip"  { type = "list" }
variable "storage_private_ip" { type = "list" }

variable "master_hostname"    { type = "list" }
variable "infra_hostname"     { type = "list" }
variable "worker_hostname"    { type = "list" }
variable "storage_hostname"   { type = "list" }

variable "openshift_identity_provider" {
    # admin/admin
    default = "openshift_master_htpasswd_users={'admin': '$apr1$qSzqkDd8$fU.yI4bV8KmXD9kreFSL//'}"
}

variable "registry_volume_size" {
    default = "100"
}

variable "cloudprovider" {
    type = "map"
    default = {
        kind = "ibm"
    }
}

variable "docker_block_device" {
  description = "block device for docker, e.g. /dev/sdb" 
}

variable "gluster_block_devices" {
  type = "list"
  description = "list of block devices for glusterfs, e.g. /dev/sdc"
}

variable "storageclass_file" {
    default = "glusterfs"
}

variable "storageclass_block" {
    default = "glusterfs-block"
}


variable "ose_version" {
    default = "3.11"
}

variable "openshift_version" {
    default = "3.11"
}

variable "ansible_version" {
    default = "2.6"
}

variable "ose_deployment_type" {
    default = "openshift-enterprise"
}

variable "pod_network_cidr" {
    default = "10.128.0.0/14"
}

variable "service_network_cidr" {
     default = "172.30.0.0/16"
}

variable "host_subnet_length" {
    default = 9
}

variable "image_registry" {
  default = "registry.redhat.io"
}

variable "image_registry_path" {
   default = "/openshift3/ose-$${component}:$${version}"
}

variable "image_registry_username" {}
variable "image_registry_password" {}
variable "master_cluster_hostname" {}
variable "app_cluster_subdomain" {}
variable "cluster_public_hostname" {}

variable "dependson" {
    type = "list"
    default = []
}

# for azure storage provider, if needed
# set in main.tf of your implementation module
variable "azure_client_id"          { default = "" }
variable "azure_client_secret"      { default = "" }
variable "azure_subscription_id"    { default = "" }
variable "azure_tenant_id"          { default = "" }
variable "azure_resource_group"     { default = "" }
variable "azure_location"           { default = "" }
variable "azure_storage_account"    { default = "" }
variable "azure_storage_accountkey" { default = "" }

variable "master_cert" {
  default = ""
}

variable "master_key" {
  default = ""
}

variable "router_cert" {
  default = ""
}

variable "router_key" {
  default = ""
}

variable "router_ca_cert" {
  default = ""
}

variable "enable_monitoring" {
  default = false
}

variable "enable_logging" {
  default = false
}

variable "enable_metrics" {
  default = false
}

variable "custom_inventory" {
  type = "list"
  default = []
}

variable "openshift_admin_user" {
  default = "admin"
}

variable "openshift_admin_htpasswd" {
  description = "generate me with htpasswd util, default is \"admin\""
  default = "$apr1$qSzqkDd8$fU.yI4bV8KmXD9kreFSL//"
}

variable "registry_storage_kind" {
  default = ""
}