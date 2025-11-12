resource "azurerm_resource_group" "hp-rg" {
  name     = "hp-rg1"
  location = "central india"

}

resource "azurerm_virtual_network" "hp-vnet" {
  name                = "hp-vnet1"
  resource_group_name = azurerm_resource_group.hp-rg.name
  location            = azurerm_resource_group.hp-rg.location
  address_space       = ["10.0.0.0/16"]

}

resource "azurerm_subnet" "hp-subnet" {
  name                 = "hp-subnet1"
  resource_group_name  = azurerm_resource_group.hp-rg.name
  virtual_network_name = azurerm_virtual_network.hp-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_network_interface" "hp-nic" {
  name                = "hp-nic1"
  resource_group_name = azurerm_resource_group.hp-rg.name
  location            = azurerm_resource_group.hp-rg.location

  ip_configuration {

    name                          = "internal"
    subnet_id                     = azurerm_subnet.hp-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.hp-publicip.id

  }

}

resource "azurerm_public_ip" "hp-publicip" {
  name                = "hp-publicip1"
  resource_group_name = azurerm_resource_group.hp-rg.name
  location            = azurerm_resource_group.hp-rg.location
  allocation_method   = "Static"
  sku = "Standard"

}

resource "azurerm_network_security_group" "hp-nsg" {
  name                = "hp-nsg1"
  resource_group_name = azurerm_resource_group.hp-rg.name
  location            = azurerm_resource_group.hp-rg.location

  security_rule {
    name                       = "hp_nsg_rule1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


}

data "azurerm_key_vault" "kv" {
    name = "hp-keyvault1"
  resource_group_name = azurerm_resource_group.hp-rg.name
}

data "azurerm_key_vault_secret" "vm_username" {
    name         = "username"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "vm_password" {
    name         = "password"
  key_vault_id = data.azurerm_key_vault.kv.id
}




resource "azurerm_network_interface_security_group_association" "hp-nicnsg" {
  network_interface_id                 = azurerm_network_interface.hp-nic.id
  network_security_group_id = azurerm_network_security_group.hp-nsg.id

}

resource "azurerm_linux_virtual_machine" "hp_linux_vm" {
  name                  = "hp-vm1"
  resource_group_name   = azurerm_resource_group.hp-rg.name
  location              = azurerm_resource_group.hp-rg.location
  size = "Standard_B1s"
  admin_username        = data.azurerm_key_vault_secret.vm_username.value
  admin_password        = data.azurerm_key_vault_secret.vm_password.value
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.hp-nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

}