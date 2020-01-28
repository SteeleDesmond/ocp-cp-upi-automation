variable "ssh_user" {
  default = "root"
}

variable "ssh_password" {
  default = "passw0rd"
}

variable "ssh_private_key" {
  default = ""
}

variable "bastion_ip_address" {
  default = ""
}

variable "bastion_ssh_user" {
  default = "root"
}

variable "bastion_ssh_password" {
  default = "passw0rd"
}

variable "bastion_ssh_private_key" {
  default = ""
}

variable "ansible_playbook_dir" {
  default = ""
}

variable "ansible_playbooks" {
  type = "list"
  default = []
}

variable "ansible_playbooks_destroy" {
  type = "list"
  default = []
}


variable "ansible_inventory" {
  default = ""
}

variable "dependson" {
  type = "list"
  default = []  
}

variable "bastion_private_ip" {
  default = ""
}

variable "node_ips" {
  type = "list"
  default = []

}
variable "node_hostnames" {
  type = "list"
  default = []
}

variable "node_count" {
  default = 0
}

variable "triggerson" {
  type = "map"
  default = {}
}

variable "ansible_vars" {
  type = "map"
  default = {}
}

variable "ansible_verbosity" {
  description = "for more debug, add -vv"
  default = ""
}

variable "cleanup" {
  description = "for debugging, set to false to leave the playbooks there on success"
  default = true
}