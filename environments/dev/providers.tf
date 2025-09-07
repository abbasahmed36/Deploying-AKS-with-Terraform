terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.38"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source  = "hashicorp/helm",
      version = "~> 2.13"
    }
    random = {
      source  = "hashicorp/random",
      version = "~> 3.6"
    }
  }
}

provider "azurerm" { 
  features {}
}
