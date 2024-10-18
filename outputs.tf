#### Output for the SQL Managed Instance names and IDs
output "sqlmi_names" {
  description = "Names of the created SQL Managed Instances"
  value       = { for k, v in azurerm_mssql_managed_instance.mssqlmi : k => v.name }
}

output "sqlmi_ids" {
  description = "IDs of the created SQL Managed Instances"
  value       = { for k, v in azurerm_mssql_managed_instance.mssqlmi : k => v.id }
}

#### Output for SQLMI Failover Groups
output "sqlmi_failover_group_ids" {
  description = "IDs of the created SQLMI Failover Groups"
  value       = { for k, v in azurerm_mssql_managed_instance_failover_group.sqlmi_fg : k => v.id }
}

#### Output for SQLMI Managed Instance Administrator Information
output "sqlmi_administrators" {
  description = "Administrator details of the SQL Managed Instances"
  value       = { for k, v in azurerm_mssql_managed_instance_active_directory_administrator.sqlmi : k => {
    login_username = v.login_username
    object_id      = v.object_id
    tenant_id      = v.tenant_id
  }}
}

#### Output for Key Vaults associated with SQLMIs
output "sqlmi_keyvault_ids" {
  description = "Key Vault IDs associated with SQLMIs"
  value       = { for k, v in data.azurerm_key_vault.sqlmi : k => v.id }
}

#### Output for Storage Accounts used in SQLMIs
output "sqlmi_storage_account_ids" {
  description = "Storage Account IDs used for SQLMI diagnostics"
  value       = { for k, v in data.azurerm_storage_account.sqlmi : k => v.id }
}

#### Output for Diagnostic Settings of SQLMIs
output "sqlmi_diagnostic_settings_ids" {
  description = "IDs of the diagnostic settings applied to SQLMIs"
  value       = { for k, v in azurerm_monitor_diagnostic_setting.sqlmi : k => v.id }
}

#### Output for Vulnerability Assessment of SQLMIs
output "sqlmi_vulnerability_assessment_ids" {
  description = "IDs of the vulnerability assessments applied to SQLMIs"
  value       = { for k, v in azurerm_mssql_managed_instance_vulnerability_assessment.sqlmi : k => v.id }
}

#### Output for Entra ID Role Assignments
output "sqlmi_role_assignment_ids" {
  description = "Role assignment IDs for SQLMIs in Entra ID (Azure AD)"
  value       = { for k, v in azuread_directory_role_assignment.sqlmi : k => v.id }
}

#### Output for SQLMI Security Alert Policies
output "sqlmi_security_alert_policy_ids" {
  description = "IDs of the security alert policies applied to SQLMIs"
  value       = { for k, v in azurerm_mssql_managed_instance_security_alert_policy.sqlmi : k => v.id }
}

#### Output for SQLMI Transparent Data Encryption
output "sqlmi_tde_ids" {
  description = "IDs of the Transparent Data Encryption settings for SQLMIs"
  value       = { for k, v in azurerm_mssql_managed_instance_transparent_data_encryption.sqlmi : k => v.id }
}