variable "inputs" {
  description = "Map of inputs containing configurations for SQL Managed Instances, diagnostics, and failover groups."

  type = object({
    location    = string
    admin_user  = string

    tags = map(string)

    vmdiags = map(object({
      rg = string
    }))

    rgs = map(object({
      existing = bool
      tags     = map(string)
    }))

    backup = object({
      rg   = string
      name = string
    })

    vnet = object({
      rg   = string
      name = string
    })

    log_analytics = map(object({
      rg     = string
      remote = bool
    }))

    sqlmi = map(object({
      existing                     = optional(bool, false)
      resource_group               = string
      subnet                       = string
      virtual_network              = string
      virtual_network_rg           = string
      storage_rg                   = string
      license_type                 = optional(string, "BasePrice")
      sku_name                     = optional(string, "GP_Gen5")
      storage_size_in_gb           = optional(number, 32)
      vcores                       = optional(number, 4)
      storage_account_type         = optional(string, "GRS")
      retention_days               = optional(number, 20)
      storage                      = optional(string, null)
      container                    = optional(string, null)
      keyvault_key                 = optional(string, null)
      auto_rotate                  = optional(bool, true)
      admin                        = optional(string, null)
      timezone_id                  = optional(string, "US Eastern Standard Time")
      azuread_authentication_only   = optional(bool, true)
      tags                         = map(string)

      #Diagnostics configuration for SQLMI
      sqlmi_diagnostics = optional(object({
        workspace = optional(string, null)  # Log Analytics workspace
        storage   = optional(string, null)  # Storage account for diagnostics
        retention = optional(number, 30)    # Retention period for logs/metrics
      }), {})
    }))

    sqlmi_fg = map(object({
      mode          = optional(string, "Automatic")
      grace_minutes = optional(number, 60)
      primary       = string                    
      primary_rg    = string                    
      secondary     = string                    
      secondary_rg  = string                    
    }))

  })
}

variable "admin_password" {
  type = string
  description = "Password for the SQL Managed Instance administrator"
  default     = random_password.admin_password.result
}
