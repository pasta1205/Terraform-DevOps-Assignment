output "public_instance_id" {
  description = "Public EC2 Instance ID"
  value       = aws_instance.public_ec2.id
}

output "public_instance_public_ip" {
  description = "Public EC2 Public IP"
  value       = aws_instance.public_ec2.public_ip
}

output "public_instance_private_ip" {
  description = "Public EC2 Private IP"
  value       = aws_instance.public_ec2.private_ip
}