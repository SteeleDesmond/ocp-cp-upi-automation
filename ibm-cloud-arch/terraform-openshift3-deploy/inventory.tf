locals {
    gluster_storage_devices = "${join(",", formatlist("\"%v\"", var.gluster_block_devices))}"
    registry_storage_kind = "${var.registry_storage_kind != "" ? var.registry_storage_kind : 
      (var.storage_count > 0 ? "glusterfs" : "")}"
}

data "template_file" "ansible_inventory_base" {
  template = <<EOF
[OSEv3:children]
masters
etcd
nodes
${var.storage_count > 0 ? "glusterfs" : ""}

[OSEv3:vars]
ansible_ssh_user=${var.ssh_user}
${var.ssh_user == "root" ? "" : "ansible_become=true"}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

openshift_deployment_type=${var.ose_deployment_type}
openshift_release=v${var.openshift_version}
containerized=true
openshift_use_crio=false
os_sdn_network_plugin_name=redhat/openshift-ovs-networkpolicy
osm_cluster_network_cidr=${var.pod_network_cidr}
openshift_portal_net=${var.service_network_cidr}
osm_host_subnet_length=${var.host_subnet_length}
openshift_master_api_port=443
openshift_master_console_port=443
os_firewall_use_firewalld=true
# disable docker_storage check on non-rhel since the python-docker library cannot connect to docker for some reason
openshift_disable_check=docker_storage,docker_image_availability,package_version
oreg_auth_user=${var.image_registry_username}
oreg_auth_password=${var.image_registry_password}
oreg_test_login=false
openshift_certificate_expiry_fail_on_warn=false
openshift_docker_options='--selinux-enabled --insecure-registry ${var.service_network_cidr} --log-driver=json-file --log-opt max-size=1M --log-opt max-file=3'
# master console
openshift_master_cluster_method=native
openshift_master_cluster_hostname=${var.master_cluster_hostname}
openshift_master_cluster_public_hostname=${var.cluster_public_hostname}
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]
openshift_master_htpasswd_users={'${var.openshift_admin_user}': '${var.openshift_admin_htpasswd}'}
# if we're using oidc, and it uses a trusted cert, we can use the system truststore
openshift_master_openid_ca_file=/etc/ssl/certs/ca-bundle.crt

# cluster console
openshift_console_install=true

# router
openshift_master_default_subdomain=${var.app_cluster_subdomain}

# registry
openshift_hosted_registry_storage_kind=${local.registry_storage_kind}
openshift_hosted_registry_storage_volume_size=${var.registry_volume_size}Gi
EOF
}

data "template_file" "ansible_inventory_master_certs" {
    template = <<EOF
# master certs
openshift_master_named_certificates=[{'certfile': '~/master.crt', 'keyfile': '~/master.key', 'names': ['${var.cluster_public_hostname}']}]
openshift_master_overwrite_named_certificates=true
EOF
}

data "template_file" "ansible_inventory_router_certs" {
    template = <<EOF
# router certs
openshift_hosted_router_certificate={'certfile': '~/router.crt', 'keyfile': '~/router.key', 'cafile': '~/router_ca.crt'}
openshift_console_cert=~/router.crt
openshift_console_key=~/router.key

# registry certs
openshift_hosted_registry_routetermination=reencrypt
openshift_hosted_registry_routecertificates={'certfile': '~/router.crt', 'keyfile': '~/router.key', 'cafile': '~/router_ca.crt'}
EOF
}

data "template_file" "ansible_inventory_logging" {
   template = <<EOF
# logging
openshift_logging_install_logging="${var.enable_logging}"
openshift_logging_es_pvc_dynamic=true
openshift_logging_es_pvc_storage_class_name=${var.storageclass_block}
openshift_logging_es_pvc_size=20Gi
openshift_logging_es_ops_nodeselector={"node-role.kubernetes.io/infra":"true"}
openshift_logging_es_nodeselector={"node-role.kubernetes.io/infra":"true"}
openshift_logging_kibana_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_logging_curator_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_logging_es_cluster_size=${var.infra_count}
openshift_logging_es_memory_limit=8Gi
openshift_logging_es_ops_memory_limit=8Gi
EOF

}

data "template_file" "ansible_inventory_monitoring" {
   template = <<EOF
# monitoring
openshift_cluster_monitoring_operator_install="${var.enable_monitoring}"
openshift_cluster_monitoring_operator_prometheus_storage_enabled=true
openshift_cluster_monitoring_operator_prometheus_storage_class_name=${var.storageclass_block}
openshift_cluster_monitoring_operator_alertmanager_storage_enabled=true
openshift_cluster_monitoring_operator_alertmanager_storage_class_name=${var.storageclass_block}
openshift_cluster_monitoring_operator_node_selector={"node-role.kubernetes.io/infra":"true"}
EOF

}

data "template_file" "ansible_inventory_metrics" {
   template = <<EOF
# metrics
openshift_metrics_install_metrics="${var.enable_metrics}"
openshift_metrics_cassandra_storage_type=dynamic
openshift_metrics_cassandra_pvc_storage_class_name=${var.storageclass_block}
openshift_metrics_hawkular_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_cassandra_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_heapster_nodeselector={"node-role.kubernetes.io/infra": "true"}
openshift_metrics_storage_volume_size=20Gi
EOF

}

data "template_file" "ansible_inventory_storage_gluster" {
    count = "${var.storage_count > 0 ? 1 : 0}"
    template = <<EOF
openshift_storage_glusterfs_block_deploy=true
openshift_storage_glusterfs_block_storageclass=true
openshift_storage_glusterfs_storageclass=true
openshift_storage_glusterfs_storageclass_default=true

# gluster images
openshift_storage_glusterfs_image=${var.image_registry}/rhgs3/rhgs-server-rhel7:v${var.openshift_version}
openshift_storage_glusterfs_block_image=${var.image_registry}/rhgs3/rhgs-gluster-block-prov-rhel7:v${var.openshift_version}
openshift_storage_glusterfs_s3_image=${var.image_registry}/rhgs3/rhgs-s3-server-rhel7:v${var.openshift_version}
openshift_storage_glusterfs_heketi_image=${var.image_registry}/rhgs3/rhgs-volmanager-rhel7:v${var.openshift_version}

EOF

}

data "template_file" "ansible_inventory_nodes" {
    template = <<EOF
[masters]
${join("\n", var.master_hostname)}

[etcd]
${join("\n", formatlist("%v etcd_ip=%v",var.master_hostname, var.master_private_ip))}

${var.storage_count > 0 ? "[glusterfs]" : ""}
${var.storage_count > 0 ? "${join("\n", formatlist("%v glusterfs_devices='[ %v ]' openshift_node_group_name='node-config-compute'", var.storage_hostname, local.gluster_storage_devices))}" : ""}

[nodes]
${join("\n", formatlist("%v openshift_node_group_name=\"node-config-master\"", var.master_hostname))}
${join("\n", formatlist("%v openshift_node_group_name=\"node-config-infra\"", var.infra_hostname))}
${join("\n", formatlist("%v openshift_node_group_name=\"node-config-compute\"", var.worker_hostname))}
${join("\n", formatlist("%v openshift_schedulable=True openshift_node_group_name=\"node-config-compute\"", var.storage_hostname))}
EOF
}

#--------------------------------#
#--------------------------------#
# ansible inventory file
data "template_file" "ansible_inventory" {
    template = <<EOF
${data.template_file.ansible_inventory_base.rendered}
${var.master_cert != "" ? "${join("\n", data.template_file.ansible_inventory_master_certs.*.rendered)}" : ""}
${var.router_cert != "" ? "${join("\n", data.template_file.ansible_inventory_router_certs.*.rendered)}" : ""}
${data.template_file.ansible_inventory_monitoring.rendered}
${data.template_file.ansible_inventory_logging.rendered}
${data.template_file.ansible_inventory_metrics.rendered}
${join("\n", data.template_file.ansible_inventory_storage_gluster.*.rendered)}
${join("\n", var.custom_inventory)}
${data.template_file.ansible_inventory_nodes.rendered}
EOF
}