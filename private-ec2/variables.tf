variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "public_subnet_id" {
  description = "Subnet for public EC2"
  type        = string
}

variable "private_subnet_id" {
  description = "Subnet for private EC2"
  type        = string
}