output "endpoint" {
  description = "RDS endpoint — use this in Vault database secrets engine config and K8s ConfigMaps (replaces 192.168.56.1)"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "RDS port — always 3306 for MySQL"
  value       = aws_db_instance.main.port
}

output "instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "security_group_id" {
  description = "RDS security group ID — referenced if you need to add extra ingress rules"
  value       = aws_security_group.rds.id
}

output "connection_string" {
  description = "MySQL connection string for reference — password not included"
  value       = "mysql -h ${aws_db_instance.main.address} -P ${aws_db_instance.main.port} -u ${aws_db_instance.main.username}"
  sensitive   = false
}
