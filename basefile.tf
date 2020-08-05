provider "azurerm" {
  
  subscription_id = "__subscription_id__"
  client_id       = "__client_id__"
  client_secret   = "__client_secret__"
  tenant_id       = "__tenant_id__"
  
  features {}
}
 resource "azurerm_resource_group" "ping" {
  name     = "ping-ping"
  location = "southeastasia"
}

resource "azurerm_virtual_network" "ping" {
  name                = "ping-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ping.location
  resource_group_name = azurerm_resource_group.ping.name
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.ping.name
  virtual_network_name = azurerm_virtual_network.ping.name
  address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.ping.name
  virtual_network_name = azurerm_virtual_network.ping.name
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "frontend" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.ping.location
  resource_group_name = azurerm_resource_group.ping.name

  security_rule {
    name                       = "all-tcp-welcome"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend" {
  name                = "backend-nsg"
  location            = azurerm_resource_group.ping.location
  resource_group_name = azurerm_resource_group.ping.name

  security_rule {
    name                       = "all-tcp-welcome"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "ping-k8s"
  location            = azurerm_resource_group.ping.location
  resource_group_name = azurerm_resource_group.ping.name
  dns_prefix          = "ping-k8s"
  
  network_profile {
    network_plugin      = "azure"
    docker_bridge_cidr  = "172.17.0.1/16"
    dns_service_ip      = "10.2.0.10"
    service_cidr        = "10.2.0.0/24"
  }
  
  default_node_pool {
    name           = "basepool"
    node_count     = 1
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.backend.id
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = true
    }

    oms_agent {
      enabled = false
    }
  }
}


resource "azurerm_api_management" "example" {
  name                = "ping-apim"
  location            = azurerm_resource_group.ping.location
  resource_group_name = azurerm_resource_group.ping.name
  publisher_name      = "BRB"
  publisher_email     = "igo@brb.io"

  sku_name = "Developer_1"
 
  virtual_network_configuration {
    subnet_id = azurerm_subnet.frontend.id
  }
   
}
