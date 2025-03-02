output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web_server.public_ip
}

output "db_server_private_ip" {
  description = "Private IP of the database server"
  value       = aws_instance.db_server.private_ip
}
