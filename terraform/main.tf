resource "azurerm_resource_group" "test-rg" {
  name     = "test-rg1"
  location = "central india"
}

resource "azurerm_virtual_network" "test-vnet" {
  name                = "test-vnet1"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location
  address_space       = ["10.0.0.0/16"]

}

resource "azurerm_subnet" "test-subnet" {
  name                 = "test-subnet1"
  virtual_network_name = azurerm_virtual_network.test-vnet.name
  resource_group_name  = azurerm_resource_group.test-rg.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "test-pip" {
  name                = "test-pip1"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location
  allocation_method   = "Static" # or "Dynamic"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nsg-test1" {
  name                = "test-nsg"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Add more rules as needed, e.g., HTTP(80), HTTPS(443)
}

# OR associate the NSG to the subnet instead:
resource "azurerm_subnet_network_security_group_association" "subnetnsg" {
  subnet_id                 = azurerm_subnet.test-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg-test1.id
}

# Associate the NSG to the NIC
# resource "azurerm_network_interface_security_group_association" "example" {
#   network_interface_id      = azurerm_network_interface.example.id
#   network_security_group_id = azurerm_network_security_group.example.id
# }

resource "azurerm_network_interface" "test-nic" {
  name                = "nic-test1"
  resource_group_name = azurerm_resource_group.test-rg.name
  location            = azurerm_resource_group.test-rg.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test-pip.id
  }

}



resource "azurerm_linux_virtual_machine" "test-vm" {
  name                            = "test-vm1"
  resource_group_name             = azurerm_resource_group.test-rg.name
  location                        = azurerm_resource_group.test-rg.location
  size                            = "Standard_F2"
  admin_username                  = "rama321"
  admin_password                  = "Admin7654321"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.test-nic.id]
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
