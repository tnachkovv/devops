output "load_balancer_endpoint" {
  description = "The public DNS address of the load balancer"
  value       = aws_lb.web_lb.dns_name
}

output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.ep_database_qa.address
}

output "database_port" {
  description = "The port of the database"
  value       = aws_db_instance.ep_database_qa.port
}
