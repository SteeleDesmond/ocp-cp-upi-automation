locals {
    icp_pub_key    = "${tls_private_key.ssh.public_key_openssh}"
    icp_priv_key   = "${tls_private_key.ssh.private_key_pem}"
    ssh_user       = "${var.ssh_user}"
    ssh_key_base64 = "${base64encode(tls_private_key.ssh.private_key_pem)}"

    # This is just to have a long list of disabled items to use in icp-deploy.tf
    disabled_list = "${list("disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled")}"
    disabled_management_services = "${zipmap(var.disabled_management_services, slice(local.disabled_list, 0, length(var.disabled_management_services)))}"
}

##################################
### Deploy ICP to cluster
##################################
module "icpprovision" {
    source = "github.com/ibm-cloud-architecture/terraform-module-icp-deploy.git?ref=2.3.6"

    # Provide IP addresses for master, proxy and workers
    boot-node = "${vsphere_virtual_machine.icpmaster.0.default_ip_address}"
    icp-host-groups = {
        master = ["${vsphere_virtual_machine.icpmaster.*.default_ip_address}"]
        proxy = ["${vsphere_virtual_machine.icpproxy.*.default_ip_address}"]
        worker = ["${vsphere_virtual_machine.icpworker.*.default_ip_address}"]
        // make the master nodes managements nodes if we don't have any specified
        management = "${slice(concat(vsphere_virtual_machine.icpmanagement.*.default_ip_address,
                                     vsphere_virtual_machine.icpmaster.*.default_ip_address),
                              0, var.management["nodes"] > 0 ? length(vsphere_virtual_machine.icpmanagement.*.default_ip_address) :  length(vsphere_virtual_machine.icpmaster.*.default_ip_address))}"
    }

    # Provide desired ICP version to provision
    icp-version = "${var.icp_inception_image}"

    parallell-image-pull = "${var.parallel_image_pull}"

    /* Workaround for terraform issue #10857
     When this is fixed, we can work this out autmatically */
    cluster_size  = "${var.master["nodes"] +
        var.worker["nodes"] +
        var.proxy["nodes"] +
        var.management["nodes"]}"

    ###################################################################################################################################
    ## You can feed in arbitrary configuration items in the icp_configuration map.
    ## Available configuration items availble from https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/installing/config_yaml.html
    icp_config_file = "./icp-config.yaml"
    icp_configuration = {
      "network_cidr"                    = "${var.network_cidr}"
      "service_cluster_ip_range"        = "${var.service_network_cidr}"
      "cluster_name"                    = "${var.instance_name}-cluster"
      "calico_ip_autodetection_method"  = "first-found"
      "default_admin_password"          = "${var.icppassword}"
      # This is the list of disabled management services
      "management_services"             = "${local.disabled_management_services}"
    }

    # We will let terraform generate a new ssh keypair
    # for boot master to communicate with worker and proxy nodes
    # during ICP deployment
    generate_key    = false
    icp_pub_key     = "${local.icp_pub_key}"
    icp_priv_key    = "${local.icp_priv_key}"

    # SSH user and key for terraform to connect to newly created VMs
    # ssh_key is the private key corresponding to the public assumed to be included in the template
    ssh_user        = "${local.ssh_user}"
    ssh_key_base64  = "${local.ssh_key_base64}"
    ssh_agent       = false
}
