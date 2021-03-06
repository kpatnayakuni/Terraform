# Resource Group
resource "azurerm_resource_group" "arg-01" {
  name     = var.resourceGroupName
  location = var.location
}

# Public ip for load balancer
resource "azurerm_public_ip" "apip-01" {
  name                    = var.publicIPAddressName
  resource_group_name     = azurerm_resource_group.arg-01.name
  location                = azurerm_resource_group.arg-01.location
  allocation_method       = "Dynamic"
  domain_name_label       = var.dnsLabelPrefix
  ip_version              = "IPV4"
  idle_timeout_in_minutes = 4
}

# Security group for subnet 
resource "azurerm_network_security_group" "ansg-01" {
  name                = var.networkSecurityGroupName
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  security_rule {
    name                       = "rdp"
    priority                   = 300
    access                     = "Allow"
    direction                  = "Inbound"
    destination_port_range     = 3389
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "avn-01" {
  name                = var.virtualNetworkName
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  address_space       = [var.addressPrefix]
}

# Subnet
resource "azurerm_subnet" "as-01" {
  name                 = var.subnetName
  resource_group_name  = azurerm_resource_group.arg-01.name
  virtual_network_name = azurerm_virtual_network.avn-01.name
  address_prefixes     = [var.subnetAddressRange]
}

# Associate subnet and network security group 
resource "azurerm_network_interface_security_group_association" "anisga-01" {
  network_interface_id      = azurerm_network_interface.anic-01.id
  network_security_group_id = azurerm_network_security_group.ansg-01.id
}

# Network interface
resource "azurerm_network_interface" "anic-01" {
  name                = lower(join("", [var.vmName, "-nic"]))
  resource_group_name = azurerm_resource_group.arg-01.name
  location            = azurerm_resource_group.arg-01.location
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.apip-01.id
    subnet_id                     = azurerm_subnet.as-01.id
  }
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "avm-01" {
  name                     = var.vmName
  resource_group_name      = azurerm_resource_group.arg-01.name
  location                 = azurerm_resource_group.arg-01.location
  size                     = var.vmsize
  admin_username           = var.adminUsername
  admin_password           = var.adminPassword
  network_interface_ids    = [azurerm_network_interface.anic-01.id]
  enable_automatic_updates = true
  provision_vm_agent       = true
  source_image_reference {
    publisher = "MicrosoftVisualStudio"
    offer     = "visualstudio2019latest"
    sku       = "vs-2019-comm-latest-ws2019"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
