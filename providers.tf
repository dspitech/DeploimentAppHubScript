# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# providers.tf — Configuration du provider Azure et du backend
# ============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.2.0"

  # Recommandé pour un projet "professionnel" : état distant partagé
  # (à décommenter et adapter une fois le storage account créé)
  #
  # backend "azurerm" {
  #   resource_group_name  = "RG-TFSTATE"
  #   storage_account_name = "sttfstatehubspoke"
  #   container_name       = "tfstate"
  #   key                  = "hub-spoke.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}
