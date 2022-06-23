# Network Interface
resource "azurerm_network_interface" "thehackerish-vm-hackbox-nic" {
  name                = "thehackerish-vm-hackbox-nic"
  location            = data.azurerm_resource_group.thehackerish-rg.location
  resource_group_name = data.azurerm_resource_group.thehackerish-rg.name

  ip_configuration {
    name                          = "thehackerish-vm-hackbox-nic-config"
    subnet_id                     = azurerm_subnet.thehackerish-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.13.37.200"
  }
}

resource "azurerm_network_interface_nat_rule_association" "thehackerish-vm-hackbox-nic-nat" {
  network_interface_id  = azurerm_network_interface.thehackerish-vm-hackbox-nic.id
  ip_configuration_name = "thehackerish-vm-hackbox-nic-config"
  nat_rule_id           = azurerm_lb_nat_rule.thehackerish-lb-nat-ssh.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "thehackerish-vm-hackbox" {
  name                = "thehackerish-vm-hackbox"
  computer_name       = var.hackbox-hostname
  resource_group_name = data.azurerm_resource_group.thehackerish-rg.name
  location            = data.azurerm_resource_group.thehackerish-rg.location
  size                = var.hackbox-size
  disable_password_authentication = false
  admin_username      = var.linux-user
  admin_password      = random_string.linuxpass.result
  network_interface_ids = [
    azurerm_network_interface.thehackerish-vm-hackbox-nic.id,
  ]

  os_disk {
    name                 = "thehackerish-vm-hackbox-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11-gen2"
    version   = "latest"
  }

  tags = {
    DoNotAutoShutDown = "yes"
  }
}