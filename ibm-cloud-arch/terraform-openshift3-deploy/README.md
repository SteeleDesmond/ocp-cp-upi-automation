## terraform-openshift3-deploy

This module generates an inventory file for Openshift 3 installation and deploys the cluster.  This is meant to be used as a module, make sure your module implementation sets all the variables in its terraform.tfvars file.

Here is an example usage.  Normally we provision infrastructure first before executing this module.

```terraform
module "openshift" {
  source = "github.com/ibm-cloud-architecture/terraform-openshift-deploy"

  # set this array for outputs from other resources in order to prevent 
  # installation until these are known.  For example, we set this to 
  # register with RHN before we start installation.
  dependson = [
    "${module.rhnregister.registered_resource}"
  ]

  # don't include bastion/control host in this count
  node_count              = "<total number of cluster nodes>"   

  # cluster nodes
  master_private_ip       = ["<master1>", "<master2>", "<master3>"]
  infra_private_ip        = ["<infra1>", "<infra2>", "<infra3>"]
  worker_private_ip       = ["<worker1>", "<worker2>", "<worker3>"]
  storage_private_ip      = ["<storage1>", "<storage2>", "<storage3>"]

  # use FQDNs, all names need to be resolvable from all cluster nodes including 
  # from the bastion/control host
  master_hostname         = ["master1.example.com", "master2.example.com", "master3.example.com"] 
  infra_hostname          = ["infra1.example.com", "infra2.example.com", "infra3.example.com"] 
  worker_hostname         = ["worker1.example.com", "worker2.example.com", "worker3.example.com"] 
  storage_hostname        = ["storage1.example.com", "storage2.example.com", "storage3.example.com"] 

  # docker block device, in VMware it's /dev/sdb
  docker_block_device     = "/dev/sdb"
  
  # storage nodes block devices, in VMware it's /dev/sdc
  gluster_block_devices   = ["/dev/sdc"]

  # bastion/control host connection parameters.  the openshift ansible playbooks
  # are run from here, we expect passwordless ssh to be set up from bastion host
  # to all cluster nodes
  bastion_ip_address      = "<bastion public ip>"
  bastion_ssh_user        = "<ssh user>"
  bastion_ssh_private_key = "<ssh private key>"

  # cluster node connection parameters - user should have passwordless sudo set up
  ssh_user                = "<cluster ssh user>"
  ssh_private_key         = "<cluster ssh private key>"

  cloudprovider           = {
      kind = "vsphere"
  }

  ose_version             = "3.11"
  ose_deployment_type     = "openshift-enterprise"

  # it's best to use a service account for these values
  image_registry_username = "<user for registry.redhat.io>"
  image_registry_password = "<password for registry.redhat.io>"

  # internal API endpoint - must be resolvable from all cluster nodes, a load balancer
  # in front of the master nodes in the cluster
  master_cluster_hostname = "internal-api.example.com"

  # public endpoint for console - must be in DNS and resolvable by clients, a load
  # balancer in front of the master nodes in the cluster
  cluster_public_hostname = "external-console.my-domain.com"

  # public endpoint for app route - wildcard domain that must be in DNS and resolvable 
  # by clients, a load balancer address for the infra nodes in the cluster
  app_cluster_subdomain   = "my-apps.my-domain.com"

  # size of persistent volume used to back image registry storage
  registry_volume_size    = "100"

  # overlay networks - make sure these subnets are non-overlapping with any other networks
  pod_network_cidr        = "10.128.0.0/16"
  service_network_cidr    = "10.129.0.0/24"

  # controls size of pod subnet assigned to each cluster node -- 9 means 2^9 = 512 pod 
  # addresses per node
  host_subnet_length      = "9"

  # user-provided certs for console - CN or SAN must contain "<cluster_public_hostname>"
  master_cert             = "<cert>"
  master_key              = "<private key>"

  # user-provided certs for app - CN or SAN must contain "*.<app_cluster_subdomain>"
  router_cert             = "<cert>"
  router_key              = "<private key>"
  router_ca_cert          = "<ca cert>"
}
```

See `variables.tf` for full list of variables.


## Module Output
This module produces no terraform output.  

----
