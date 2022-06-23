# Prepare the Windows group variable template with the right username and password
resource "local_file" "ansible-groupvars-windows-creation" {

  depends_on = [
    var.windows-user,
    var.domain-dns-name,
    random_string.windowspass
  ]

  content = templatefile("${path.module}/../Ansible/group_vars/windows.tmpl",
           { 
              username = var.windows-user
              password    = random_string.windowspass.result
              domain_name = var.domain-dns-name
           })

  filename = "../Ansible/group_vars/windows.yml"
}

# Prepare the Linux group variable template with the right username and password
resource "local_file" "ansible-groupvars-linux-creation" {

  depends_on = [
    var.linux-user,
    random_string.linuxpass
  ]
  
  content = templatefile("${path.module}/../Ansible/group_vars/linux.tmpl",
           { 
              username    = var.linux-user
              password    = random_string.linuxpass.result
           })

  filename = "../Ansible/group_vars/linux.yml"
}

# Provision the lab using Ansible from the hackbox machine
resource "null_resource" "ansible-provisioning" {

  # All VMs have to be up before provisioning can be initiated
  depends_on = [
    azurerm_windows_virtual_machine.thehackerish-vm-dc,
    azurerm_windows_virtual_machine.thehackerish-vm-winserv2019,
    azurerm_windows_virtual_machine.thehackerish-vm-windows10,
    azurerm_linux_virtual_machine.thehackerish-vm-hackbox,
  ]

  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    type  = "ssh"
    host  = azurerm_public_ip.thehackerish-ip.ip_address
    user  = var.linux-user
    password = random_string.linuxpass.result
  }

  # Copy Ansible folder to hackbox machine for provisioning
  provisioner "file" {
    source      = "../Ansible"
    destination = "/dev/shm"
  }

  # Kick off ansible
  provisioner "remote-exec" {
    inline = [
      "sudo apt -qq update >/dev/null && sudo apt -qq install -y git ansible sshpass > /dev/null",
      "ansible-galaxy collection install ansible.windows community.general > /dev/null",
      "cd /dev/shm/Ansible",
      "ansible-playbook -v cloudlabs.yml"
    ]
  }
}