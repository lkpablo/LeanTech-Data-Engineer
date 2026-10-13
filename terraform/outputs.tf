# The names to put in .env for this environment.
output "warehouse" {
  value = snowflake_warehouse.pipeline.name
}

output "database" {
  value = snowflake_database.sales.name
}

output "role" {
  value = snowflake_account_role.pipeline.name
}

output "service_user" {
  value = snowflake_service_user.pipeline.name
}
