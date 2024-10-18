####data block for subnet
data "azurerm_subnet" "sqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.virtual_network_rg != null
  }
  
  name                = each.value.subnet
  resource_group_name = each.value.virtual_network_rg
  virtual_network_name = each.value.virtual_network
}


###create a random password of the administrator password
resource "random_password" "admin_password" {
  length  = 16
  special = true
}


####resource block for sqlmi
resource "azurerm_mssql_managed_instance" "mssqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if !v.existing
  }

  name                = each.key
  resource_group_name = each.value.resource_group
  location            = var.inputs.location

  license_type          = each.value.license_type
  sku_name              = each.value.sku_name
  storage_size_in_gb    = each.value.storage_size_in_gb
  subnet_id             = try(data.azurerm_subnet.sqlmi[each.key].id, null) 
  vcores                = each.value.vcores
  storage_account_type  = each.value.storage_account_type
  timezone_id           = each.value.timezone_id

  administrator_login          = var.inputs.admin_user
  administrator_login_password = var.admin_password  

  identity {
    type = "SystemAssigned"
  }
}


####data block for primary sqlmi 
data "azurerm_mssql_managed_instance" "sqlmi_primary" {
  for_each = {
     for k, v in var.inputs.sqlmi_fg : k => v if v.primary != null && v.primary_rg !=null
  }
  name                = each.value.primary
  resource_group_name = each.value.primary_rg
}


####data block for secondary sqlmi 
data "azurerm_mssql_managed_instance" "sqlmi_secondary" {
  for_each = {
     for k, v in var.inputs.sqlmi_fg : k => v if v.secondary != null && v.secondary_rg !=null
  }
  name                = each.value.secondary
  resource_group_name = each.value.secondary_rg
}


####resource block for sqlmi failover group
resource "azurerm_mssql_managed_instance_failover_group" "sqlmi_fg" {
  for_each = {
    for k, v in var.inputs.sqlmi_fg : k => v 
  }
  name                        = each.key
  location                    = var.inputs.location
  managed_instance_id         = try(azurerm_mssql_managed_instance.mssqlmi[each.value.primary].id,data.azurerm_mssql_managed_instance.sqlmi_primary[each.value.primary].id)
  partner_managed_instance_id = try(azurerm_mssql_managed_instance.mssqlmi[each.value.secondary].id,data.azurerm_mssql_managed_instance.sqlmi_secondary[each.value.secondary].id)

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
  depends_on = [
    azurerm_mssql_managed_instance.mssqlmi,
  ]
}


####datablock for keyvault
data "azurerm_key_vault" "sqlmi" {
    for_each = {
      for k, v in var.inputs.sqlmi : k => v if v.keyvault != null
    }
    name                = each.value.keyvault
    resource_group_name = each.value.keyvault_rg

}


####datablock for keyvault key
data "azurerm_key_vault_key" "sqlmi" {
    for_each = {
      for k, v in var.inputs.sqlmi : k => v if v.keyvault != null
    }
    key_vault_id        = data.azurerm_key_vault.sqlmi[each.key].id
    name                = each.value.keyvault_key


}


####resource block for sqlmi transparent data encryption
resource "azurerm_mssql_managed_instance_transparent_data_encryption" "sqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.keyvault != null
  }
  
  managed_instance_id = try(azurerm_mssql_managed_instance.mssqlmi[each.key].id,null)
  key_vault_key_id    = try(data.azurerm_key_vault_key.sqlmi[each.key].id,null)
  auto_rotation_enabled = each.value.auto_rotate
  depends_on = [
    azurerm_mssql_managed_instance.mssqlmi,
    azurerm_key_vault.kv_sqlmi
  ]

}


####datablock for storage account
data "azurerm_storage_account" "sqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.storage != null
  }
  name                                          = each.value.storage
  resource_group_name                           = each.value.storage_rg
}


####datablock for storage account container
data "azurerm_storage_container" "sqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.storage != null && v.container != null
  }
  name                 = each.value.container
  storage_account_name = each.value.storage
}


####resource block for sqlmi security alert policy
resource "azurerm_mssql_managed_instance_security_alert_policy" "sqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.storage != null
  }
  resource_group_name        = each.value.resource_group
  managed_instance_name      = each.key
  enabled                    = true
  disabled_alerts            = try(each.value.disabled_alerts, null)
#  storage_endpoint           = data.azurerm_storage_account.sqlmi[each.key].primary_blob_endpoint
#  storage_account_access_key = data.azurerm_storage_account.sqlmi[each.key].primary_access_key
  retention_days             = each.value.retention_days

  depends_on = [
    azurerm_mssql_managed_instance.mssqlmi,
  ]
}


####resource for sqlmi vulnerability assessment
resource "azurerm_mssql_managed_instance_vulnerability_assessment" "sqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.storage != null && v.container != null
  }
  managed_instance_id        = try(azurerm_mssql_managed_instance.mssqlmi[each.key].id,null)
  storage_container_path     = "${data.azurerm_storage_account.sqlmi[each.key].primary_blob_endpoint}${data.azurerm_storage_container.sqlmi[each.key].name}/"
  #storage_account_access_key = try(data.azurerm_storage_account.sqlmi[each.key].primary_access_key, data.azurerm_storage_account.sqlmi[each.key].secondary_access_key)

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = try(each.value.assessment_vulnerability_email_addresses,null)
  }
  depends_on = [azurerm_mssql_managed_instance_security_alert_policy.sqlmi]
}


####data block for azure ad group
data "azuread_group" "sqlmi" {
  for_each = {
    for k, v in var.inputs.admin : k => v if v.admin != null
  }

  display_name = each.value.admin
}


####resource block for Entra id role 
resource "azuread_directory_role" "sqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.admin != null
  }
  
  display_name = "Directory Readers"

}


####resource block for Entra id role assignment
resource "azuread_directory_role_assignment" "sqlmi" {
  for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.admin != null
  }
  role_id      = azuread_directory_role.sqlmi[each.key].object_id
  principal_object_id = azurerm_mssql_managed_instance.mssqlmi[each.key].identity.0.principal_id

  depends_on = [
   azuread_directory_role.sqlmi
  ]

  lifecycle {
    ignore_changes = [
      role_id
    ]
  }

}


####resource block for sqlmi AD administrator
resource "azurerm_mssql_managed_instance_active_directory_administrator" "sqlmi" {
    for_each = {
    for k, v in var.inputs.sqlmi : k => v if v.admin != null
  }
 
  managed_instance_id            = try(azurerm_mssql_managed_instance.mssqlmi[each.key].id,null)
  login_username                 = each.value.admin
  object_id                      = data.azuread_group.sqlmi[each.key].object_id
  tenant_id                      = data.azurerm_client_config.current.tenant_id
  azuread_authentication_only    = each.value.azuread_authentication_only

  depends_on = [
   azuread_directory_role_assignment.sqlmi
  ]


}


####data block for azure monitor diagnostic categories
data "azurerm_monitor_diagnostic_categories" "sqlmi" {
    for_each = {
        for sqlmi in var.inputs.sqlmi : sqlmi.name => sqlmi if !sqlmi.existing 
    }
    resource_id                                 = azurerm_mssql_managed_instance.mssqlmi[each.key].id
    depends_on = [
      azurerm_mssql_managed_instance.mssqlmi
    ]
  }


####resource block for azure monitor diagnostic setting
resource "azurerm_monitor_diagnostic_setting" "sqlmi" {
  for_each = {
    for sqlmi_key, sqlmi_data in var.inputs.sqlmi : sqlmi_key => sqlmi_data
    if sqlmi_data.sqlmi_diagnostics != null
  }

  name                       = "${each.key}-diag"
  target_resource_id         = azurerm_mssql_managed_instance.mssqlmi[each.key].id
  log_analytics_workspace_id = try(data.azurerm_log_analytics_workspace.loganalytics[each.value.sqlmi_diagnostics.workspace].id, null)
  storage_account_id         = try(data.azurerm_storage_account.storage[each.value.sqlmi_diagnostics.storage].id, null)

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.sqlmi[each.key].logs
    content {
      category = log.value
      enabled  = true
      retention_policy {
        enabled = each.value.sqlmi_diagnostics.storage != null ? true : false
        days    = each.value.sqlmi_diagnostics.storage != null ? each.value.sqlmi_diagnostics.retention : null
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.sqlmi[each.key].metrics
    content {
      category = metric.value
      enabled  = true
      retention_policy {
        enabled = each.value.sqlmi_diagnostics.storage != null ? true : false
        days    = each.value.sqlmi_diagnostics.storage != null ? each.value.sqlmi_diagnostics.retention : null
      }
    }
  }

  depends_on = [
    azurerm_mssql_managed_instance.mssqlmi,
    data.azurerm_monitor_diagnostic_categories.sqlmi
  ]
}