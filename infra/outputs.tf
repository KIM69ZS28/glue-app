# output "diag_instance_id" {
#   description = "ID of the diagnostic EC2 instance"
#   value       = aws_instance.diag_server.id
# }

# output "diag_instance_private_ip" {
#   description = "Private IP of the diagnostic EC2 instance"
#   value       = aws_instance.diag_server.private_ip
# }

# output "ssm_endpoints" {
#   description = "List of SSM VPC endpoints created"
#   value       = [for e in aws_vpc_endpoint.ssm_endpoints : e.service_name]
# }
