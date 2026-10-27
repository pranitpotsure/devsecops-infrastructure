# Expose the RDS endpoint for application configuration.
output "endpoint" {
  description = "RDS endpoint hostname and port."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS database hostname."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS database port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "Security group attached to the database."
  value       = aws_security_group.database.id
}

output "managed_master_user_secret_arn" {
  description = "ARN of the RDS-managed master credential secret."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
