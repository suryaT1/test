terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"   # latest stable
    }
  }
}

provider "azurerm" {
  features {}
}

# ───────────────────────────────
# 1️⃣ Resource Group
# ───────────────────────────────
resource "azurerm_resource_group" "rg" {
  name     = "rg-func-demo"
  location = "East US"
}

# ───────────────────────────────
# 2️⃣ Storage Account (for Functions)
# ───────────────────────────────
resource "azurerm_storage_account" "storage" {
  name                     = "mystorageacctteq"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
}

# ───────────────────────────────
# 3️⃣ App Service Plan
# ───────────────────────────────
resource "azurerm_service_plan" "plan" {
  name                = "plan-func-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan (serverless)
}

# ───────────────────────────────
# 4️⃣ Function App
# ───────────────────────────────
resource "azurerm_linux_function_app" "func" {
  name                       = "pipelinetestin"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  functions_extension_version = "~4"

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"      = "python"
    "AzureWebJobsStorage"           = azurerm_storage_account.storage.primary_connection_string
    "AzureWebJobsSecretStorageType" = "Blob"
  }
}
