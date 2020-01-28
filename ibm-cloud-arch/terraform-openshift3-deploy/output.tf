output "installed_resource" {
    value = "${join(",", list(
        module.prerequisites.module_completed, 
        module.deploy_cluster.module_completed, 
        null_resource.create_cluster_admin.id))}"
}

output "openshift_inventory" {
    value = "${data.template_file.ansible_inventory.rendered}"
}

# TODO
output "openshift_admin_user" {
    value = "admin"
}

# TODO
output "openshift_admin_password" {
    value = "admin"
}