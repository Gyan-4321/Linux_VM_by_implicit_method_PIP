terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.34.0"
    }
  }
}

provider "azurerm" {
  features {

  }
  subscription_id = "2c2a83bb-a243-4d9e-a20d-ad64406de5ba"
}