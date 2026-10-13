# Account and credentials come from TF_VAR_* environment variables, never from files in the repo.
variable "organization_name" {
  description = "Snowflake organization, first part of the account identifier (ORG-ACCOUNT)."
  type        = string
}

variable "account_name" {
  description = "Snowflake account, second part of the account identifier."
  type        = string
}

variable "admin_user" {
  description = "User Terraform connects with (key-pair authentication)."
  type        = string
}

variable "admin_role" {
  description = "Role able to create warehouses, databases, roles and users."
  type        = string
  default     = "ACCOUNTADMIN"
}

variable "private_key_path" {
  description = "Path to the private key of admin_user. The key itself is never in the code or the state."
  type        = string
}

variable "service_user_public_key_path" {
  description = "Public key file of the pipeline's service user (setup/generate_keys.py)."
  type        = string
}

variable "environment" {
  description = "Prefix of every object, so dev and prod live side by side in one account."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "warehouse_size" {
  description = "Pipeline warehouse size."
  type        = string
  default     = "XSMALL"
}
