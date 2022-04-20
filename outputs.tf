output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.rds_postgres_db.db_instance_address
}

output "db_instance_endpoint" {
  description = "The connection endpoint in db_instance_address:db_instance_port format"
  value       = module.rds_postgres_db.db_instance_endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = module.rds_postgres_db.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.rds_postgres_db.db_instance_username
  sensitive   = true
}

output "db_instance_password" {
  description = "The database password (not tracked after initial terraform creation)"
  value       = module.rds_postgres_db.db_instance_password
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = module.rds_postgres_db.db_instance_port
}
