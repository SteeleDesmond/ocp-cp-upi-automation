output "module_completed" {
    value = "${join(",", concat(
        null_resource.run_playbook_create.*.id, 
        null_resource.run_playbook_destroy.*.id, 
        null_resource.cleanup.*.id))}"
}