# The account-level objects that setup/snowflake_setup.sql creates by hand, as code.
# Schemas, tables and views are not here: dbt owns them.

terraform {
  required_providers {
    snowflake = {
      source = "snowflakedb/snowflake"
    }
  }

  # Remote state, one per environment, versioned and locked (state is never committed):
  # backend "gcs" {
  #   bucket = "leantech-terraform-state"
  #   prefix = "snowflake/dev"
  # }
}

provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = var.admin_user
  role              = var.admin_role
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.private_key_path)
}

locals {
  prefix = upper(var.environment)
  # Snowflake expects the public key without its BEGIN/END lines.
  service_user_public_key = replace(replace(file(var.service_user_public_key_path), "/-----[A-Z ]+-----/", ""), "/\\s/", "")
}

resource "snowflake_warehouse" "pipeline" {
  name                = "${local.prefix}_LEANTECH_WH"
  warehouse_size      = var.warehouse_size
  auto_suspend        = 60
  initially_suspended = true
}

resource "snowflake_database" "sales" {
  name = "${local.prefix}_SALES_DW"
}

resource "snowflake_account_role" "pipeline" {
  name = "${local.prefix}_LEANTECH_PIPELINE"
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  account_role_name = snowflake_account_role.pipeline.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.pipeline.name
  }
}

resource "snowflake_grant_ownership" "database" {
  account_role_name = snowflake_account_role.pipeline.name
  on {
    object_type = "DATABASE"
    object_name = snowflake_database.sales.name
  }
}

resource "snowflake_grant_account_role" "pipeline_to_sysadmin" {
  role_name        = snowflake_account_role.pipeline.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_service_user" "pipeline" {
  name              = "${local.prefix}_SVC_LEANTECH"
  default_role      = snowflake_account_role.pipeline.name
  default_warehouse = snowflake_warehouse.pipeline.name
  rsa_public_key    = local.service_user_public_key
}

resource "snowflake_grant_account_role" "pipeline_to_user" {
  role_name = snowflake_account_role.pipeline.name
  user_name = snowflake_service_user.pipeline.name
}
