resource "aws_instance" "private_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_id

  associate_public_ip_address = false

  tags = {
    Name = "Private-EC2"
  }
}