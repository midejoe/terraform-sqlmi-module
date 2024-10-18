inputs = {
  location   = "eastus"
  admin_user = "locadm"
  
  tags = {
    APP            = "Host-encrption-test-vm"
    ENV            = "test"
    VER            = ""
    POC            = "mahathi.ravi@accenture.com"
    BU             = ""
    "DR TIER"      = ""
    DATASEN        = ""
    BO             = ""
    CC             = ""
    CI             = ""
    PatchSchedule  = ""
    Backup         = ""
    Category       = "Test"
  }

  vmdiags = {
    stvmdiagitaiprodeus01 = {
      rg = "rg-st-itai-prod-eus-01"
    }
  }

  rgs = {
    rg-museeng-paceart-itai-prod-01 = {
      existing = true
      tags     = {}
    }
  }

  backup = {
    rg   = "rg-bkup-itai-prod-eus-01"
    name = "rsv-bkup-itai-prod-eus-01"
  }

  vnet = {
    rg   = "rg-network-itai-prod-eus-01"
    name = "vnet-spk-nonepic-itai-prod-eus-01"
  }

  log_analytics = {
    log-sec-prod-eus-01 = {
      rg     = "rg-log-core-prod-eus-01"
      remote = true
    }
  }

  sqlmi = {
    sqlmi-museeng-paceart-itai-prod-eus-01 = {
      existing              = false
      resource_group        = "rg-museeng-paceart-itai-prod-01"
      subnet                = "snet-nonepic-itai-sqlmi-prod-eus-01"
      virtual_network       = "vnet-spk-nonepic-itai-prod-eus-01"
      virtual_network_rg    = "rg-network-itai-prod-eus-01"
      license_type          = "BasePrice"
      sku_name              = "GP_Gen8IM"
      storage_size_in_gb    = 1248
      vcores                = 8
      storage_account_type  = "LRS"
    }
  }

  sqlmi_fg = {
    "name" = {
      
    }
  }
}