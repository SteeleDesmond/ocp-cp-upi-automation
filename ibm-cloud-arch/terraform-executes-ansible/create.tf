resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = "${join(",", var.dependson)}"
  }
}

resource "random_id" "playbook_id" {
  byte_length = 4
}

locals {
  myid = "${random_id.playbook_id.hex}"
  playbook_dir = "/tmp/playbook_${local.myid}"
  ansible_inventory = "/tmp/playbook_${local.myid}/ansible.cfg"
  ssh_key = "/tmp/playbook_${local.myid}/ssh_key"
  triggerson = "${length(var.triggerson) != 0 ? "${join(",", formatlist("%v=%v", keys(var.triggerson), values(var.triggerson)))}" : "${format("%v=%v", "timestamp", timestamp())}" }"
}

data "template_file" "playbook_full_path" {
  count = "${length(var.ansible_playbooks)}"

  template = "${substr(element(var.ansible_playbooks, count.index), 0, 1) == "/" ? "${element(var.ansible_playbooks, count.index)}" : "${local.playbook_dir}/${element(var.ansible_playbooks, count.index)}"}"
}

resource "null_resource" "install_ansible" {
  triggers = {
    triggerson = "${local.triggerson}"
  }
  
  depends_on = [
    "null_resource.dependency",
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
    inline = [
      "echo 'exec $@' | tee /tmp/ansible_chroot.sh", 
      "chmod u+x /tmp/ansible_chroot.sh",
      "if which ansible; then exit 0; fi",
      # the fun begins here
      "set -x",
      "sudo mkdir -p /tmp/ansible_chroot/var/lib/rpm",
      "while ! sudo yum --installroot=/tmp/ansible_chroot list installed centos-release; do wget -r -l1 -np -nd http://mirror.centos.org/centos/7/os/x86_64/Packages/ -P /tmp -A 'centos-release-7*.rpm'; sudo yum --installroot=/tmp/ansible_chroot -y install /tmp/centos-release-*.rpm; rm -rf /tmp/centos-release*.rpm; done",
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

resource "null_resource" "write_ssh_key" {
  triggers = {
    triggerson = "${local.triggerson}"
  }

  depends_on = [
    "null_resource.dependency",
  ]

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    password    = "${var.bastion_ssh_password}"
    private_key = "${var.bastion_ssh_private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${local.playbook_dir}"
    ]
  }

  provisioner "file" {
    destination = "${local.ssh_key}"
    content = "${var.ssh_private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 ${local.ssh_key}",
      "chown ${var.bastion_ssh_user} ${local.ssh_key}"
    ]
  }
}

resource "null_resource" "copy_ansible_playbook" {
  count = "${var.ansible_playbook_dir != "" ? 1 : 0}"

  triggers = {
    triggerson = "${local.triggerson}"
  }

  depends_on = [
    "null_resource.dependency",
  ]

 connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    password    = "${var.bastion_ssh_password}"
    private_key = "${var.bastion_ssh_private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${local.playbook_dir}"
    ]
  }

  provisioner "file" {
    source = "${var.ansible_playbook_dir}"
    destination = "${local.playbook_dir}"
  }
}

data "template_file" "ansible_inventory" {
  template = <<EOF
[nodes]
${join("\n", formatlist("%v ansible_host=%v", var.node_hostnames, var.node_ips))}

[nodes:vars]
ansible_ssh_user=${var.ssh_user}
${var.ssh_user == "root" ? "" : "ansible_become=true"}
${var.ssh_private_key == "" ? "" : "ansible_ssh_private_key_file=${local.ssh_key}"}
${var.ssh_password == "" ? "" : "ansible_ssh_pass=${var.ssh_password}"}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=60s'
${join("\n", formatlist("%v=%v", keys(var.ansible_vars), values(var.ansible_vars)))}

EOF
}

resource "null_resource" "copy_ansible_inventory" {
  triggers = {
    triggerson = "${local.triggerson}"
  }

  depends_on = [
    "null_resource.dependency",
  ]

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    private_key = "${var.bastion_ssh_private_key}"
    password    = "${var.bastion_ssh_password}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${local.playbook_dir}"
    ]
  }

  provisioner "file" {
    content = "${var.ansible_inventory == "" ? data.template_file.ansible_inventory.rendered : var.ansible_inventory}"
    destination = "${local.ansible_inventory}"
  }
}

resource "null_resource" "run_playbook_create" {
  count = "${length(var.ansible_playbooks)}"
  
  # just run it every time, have ansible handle configuration drift
  triggers = {
    triggerson = "${local.triggerson}"
  }

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    private_key = "${var.bastion_ssh_private_key}"
    password    = "${var.bastion_ssh_password}"
  }

  provisioner "remote-exec" {
    when = "create"
    inline = [
      "set -ex",
      "export ANSIBLE_SSL_PIPELINING=$(sudo grep requiretty /etc/sudoers && echo 0 || echo 1)",
      "/tmp/ansible_chroot.sh ansible-playbook -f 20 -i ${local.ansible_inventory} ${element(data.template_file.playbook_full_path.*.rendered, count.index)} ${var.ansible_verbosity}"
    ]
  }

  depends_on = [
    "null_resource.dependency",
    "data.template_file.ansible_inventory",
    "null_resource.copy_ansible_playbook",
    "null_resource.copy_ansible_inventory",
    "null_resource.write_ssh_key",
    "null_resource.install_ansible"
  ]
}



resource "null_resource" "cleanup" {
  count = "${var.cleanup ? 1 : 0}"
  # clean up the playbooks and stuff
  triggers = {
    triggerson = "${local.triggerson}"
  }

  connection {
    type        = "ssh"
    host        = "${var.bastion_ip_address}"
    user        = "${var.bastion_ssh_user}"
    private_key = "${var.bastion_ssh_private_key}"
    password    = "${var.bastion_ssh_password}"
  }

  provisioner "remote-exec" {
    inline = [
      "rm -rf ${local.playbook_dir}"
    ]
  }

  depends_on = [
    "null_resource.run_playbook_create",
  ]
}