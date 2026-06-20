output "private_instance_id" {
  description = "Private EC2 Instance ID"
  value       = aws_instance.private_ec2.id
}

output "private_instance_private_ip" {
  description = "Private EC2 Private IP"
  value       = aws_instance.private_ec2.private_ip
}

output "private_instance_public_ip" {
  description = "Private EC2 Public IP (Expected: null)"
  value       = aws_instance.private_ec2.public_ip
}