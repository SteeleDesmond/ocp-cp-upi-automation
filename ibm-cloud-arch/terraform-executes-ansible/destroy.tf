# playbooks run on destroy. the dependencies are backward, so they run forward on destroy.
# but make sure none of these resources run commands on create
resource "null_resource" "cleanup_destroy" {
  count = "${length(var.ansible_playbooks_destroy) > 0 ? "${var.cleanup ? 1 : 0}" : 0}"
 
  depends_on = [
    "null_resource.dependency"
  ]


  # clean up the playbooks and stuff
  triggers = {
    triggerson = "${join(",", formatlist("%v=%v", keys(var.triggerson), values(var.triggerson)))}"
  }

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    private_key = "${var.bastion_ssh_private_key}"
    password    = "${var.bastion_ssh_password}"
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      # "rm -rf ${local.playbook_dir}"
    ]
  }

}

data "template_file" "playbook_full_path_destroy" {
  count = "${length(var.ansible_playbooks_destroy)}"

  template = "${substr(element(var.ansible_playbooks_destroy, count.index), 0, 1) == "/" ? "${element(var.ansible_playbooks_destroy, count.index)}" : "${local.playbook_dir}/${element(var.ansible_playbooks_destroy, count.index)}"}"

}

resource "null_resource" "run_playbook_destroy" {
  count = "${length(var.ansible_playbooks_destroy)}"
  
  # just run it every time, have ansible handle configuration drift
  triggers = {
    triggerson = "${join(",", formatlist("%v=%v", keys(var.triggerson), values(var.triggerson)))}"
  }

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    private_key = "${var.bastion_ssh_private_key}"
    password    = "${var.bastion_ssh_password}"
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "set -ex",
      "echo ${join(",", data.template_file.playbook_full_path_destroy.*.rendered)}"
    ]
  }


  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "set -ex",
      "export ANSIBLE_SSL_PIPELINING=$(sudo grep requiretty /etc/sudoers && echo 0 || echo 1)",
       "/tmp/ansible_chroot.sh ansible-playbook -f 20 -i ${local.ansible_inventory} ${element(data.template_file.playbook_full_path_destroy.*.rendered, count.index)} ${var.ansible_verbosity}"
    ]
  }

  depends_on = [
    "null_resource.cleanup_destroy"
  ]
}

resource "null_resource" "copy_ansible_playbook_destroy" {
  count = "${length(var.ansible_playbooks_destroy) > 0 ? (var.ansible_playbook_dir != "" ? 1 : 0) : 0}"

  depends_on = [
    "null_resource.run_playbook_destroy",
  ]

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    password    = "${var.bastion_ssh_password}"
    private_key = "${var.bastion_ssh_private_key}"
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "mkdir -p ${local.playbook_dir}",
    ]
  }

  provisioner "file" {
    when = "destroy"
    source = "${var.ansible_playbook_dir}"
    destination = "${local.playbook_dir}"
  }
}



resource "null_resource" "write_ssh_key_destroy" {
  count = "${length(var.ansible_playbooks_destroy) > 0 ?  1 : 0}"

  depends_on = [
    "null_resource.copy_ansible_playbook_destroy",
  ]

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    password    = "${var.bastion_ssh_password}"
    private_key = "${var.bastion_ssh_private_key}"
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "mkdir -p ${local.playbook_dir}"
    ]
  }

  provisioner "file" {
    when = "destroy"
    destination = "${local.ssh_key}"
    content = "${var.ssh_private_key}"
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "chmod 600 ${local.ssh_key}",
      "chown ${var.bastion_ssh_user} ${local.ssh_key}"
    ]
  }
}

resource "null_resource" "copy_ansible_inventory_destroy" {
  count = "${length(var.ansible_playbooks_destroy) > 0 ? 1 : 0}"

  depends_on = [
    "null_resource.write_ssh_key_destroy",
  ]

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    private_key = "${var.bastion_ssh_private_key}"
    password    = "${var.bastion_ssh_password}"
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "mkdir -p ${local.playbook_dir}"
    ]
  }

  provisioner "file" {
    when = "destroy"
    content = "${var.ansible_inventory == "" ? data.template_file.ansible_inventory.rendered : var.ansible_inventory}"
    destination = "${local.ansible_inventory}"
  }
}

resource "null_resource" "install_ansible_destroy" {
  count = "${length(var.ansible_playbooks_destroy) > 0 ? 1 : 0}"

  depends_on = [
    "null_resource.copy_ansible_inventory_destroy",
  ]

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    password    = "${var.bastion_ssh_password}"
    private_key = "${var.bastion_ssh_private_key}"
  }

  # install ansible from epel if it's not already there; in a disconnected environment we expect
  # the user to pre-install ansible in the path
  # otherwise create a centos chroot we can safely install ansible into so we don't hose the machine
  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "echo 'exec $@' | tee /tmp/ansible_chroot.sh", 
      "chmod u+x /tmp/ansible_chroot.sh",
      "if which ansible; then exit 0; fi",
      # the fun begins here
      "sudo mkdir -p /tmp/ansible_chroot/var/lib/rpm",
      "while ! sudo yum --installroot=/tmp/ansible_chroot list installed centos-release; do wget -r -l1 -np -nd http://mirror.centos.org/centos/7/os/x86_64/Packages/ -P /tmp -A 'centos-release-7*.rpm'; done",
      "while ! sudo yum --installroot=/tmp/ansible_chroot list installed centos-release; do sudo yum --installroot=/tmp/ansible_chroot -y install /tmp/centos-release-*.rpm; rm -rf /tmp/centos-release*.rpm; done",
      "while ! sudo yum --installroot=/tmp/ansible_chroot list installed epel-release; do sudo yum install --installroot=/tmp/ansible_chroot -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; done",
      "sudo rpm --root=/tmp/ansible_chroot --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-7",
      "sudo rpm --root=/tmp/ansible_chroot --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7",
      "while ! sudo yum install --installroot=/tmp/ansible_chroot -y binutils bash ansible openssh-clients; do sleep 1; done",
      "echo 'set +e' | tee /tmp/ansible_chroot.sh",
      "echo 'if ! cat /proc/mounts | grep /tmp/ansible_chroot/tmp; then sudo mount --bind /tmp /tmp/ansible_chroot/tmp; fi' | tee -a /tmp/ansible_chroot.sh",
      "echo 'if ! cat /proc/mounts | grep /tmp/ansible_chroot/dev; then sudo mount --bind /dev /tmp/ansible_chroot/dev; fi' | tee -a /tmp/ansible_chroot.sh",
      "echo 'set -e' | tee -a /tmp/ansible_chroot.sh",
      "echo 'sudo /usr/sbin/chroot /tmp/ansible_chroot \"$@\"' | tee -a /tmp/ansible_chroot.sh",
      "echo 'set +e' | tee -a /tmp/ansible_chroot.sh",
      "echo 'if cat /proc/mounts | grep /tmp/ansible_chroot/dev; then sudo umount /tmp/ansible_chroot/dev; fi' | tee -a /tmp/ansible_chroot.sh",
      "echo 'if cat /proc/mounts | grep /tmp/ansible_chroot/tmp; then sudo umount /tmp/ansible_chroot/tmp; fi' | tee -a /tmp/ansible_chroot.sh",
      "echo 'set -e' | tee -a /tmp/ansible_chroot.sh",
    ]
  }
}