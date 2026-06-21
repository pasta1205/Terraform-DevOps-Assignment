
#VPC:

resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Custom-VPC"
  }
}


#InternetGateway:

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "Custom-IGW"
  }
}


#PublicSubnet:

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public-Subnet"
  }
}


#PrivateSubnet:

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Private-Subnet"
  }
}


#ElasticIP:

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}


#NATGateway:

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "NAT-Gateway"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}


#PublicRT:

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}


#PrivateRT:

resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private-RT"
  }
}


#RTAssociation:

resource "aws_route_table_association" "public_assoc" {

  subnet_id      = aws_subnet.public_subnet.id

  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc" {

  subnet_id      = aws_subnet.private_subnet.id

  route_table_id = aws_route_table.private_rt.id
}


#FrontendSG:

resource "aws_security_group" "frontend_sg" {

  name   = "frontend-sg"
  vpc_id = aws_vpc.custom_vpc.id

  ingress {

    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}


#BackendSG:

resource "aws_security_group" "backend_sg" {

  name   = "backend-sg"
  vpc_id = aws_vpc.custom_vpc.id

  ingress {

    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"

    security_groups = [
      aws_security_group.frontend_sg.id
    ]
  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}


#FrontendEC2:

resource "aws_instance" "frontend" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public_subnet.id

  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  vpc_security_group_ids = [
    aws_security_group.frontend_sg.id
  ]

  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y httpd

systemctl enable httpd
systemctl start httpd

echo "<h1>Frontend Server Running</h1>" > /var/www/html/index.html
EOF

  tags = {
    Name = "Frontend"
  }
}

#BackendEC2:

resource "aws_instance" "backend" {

  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = aws_subnet.private_subnet.id

  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  vpc_security_group_ids = [
    aws_security_group.backend_sg.id
  ]

  associate_public_ip_address = false

  user_data = <<-EOF
#!/bin/bash

cat <<REPO > /etc/yum.repos.d/mongodb-org-7.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
REPO

dnf install -y mongodb-org

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf

systemctl enable mongod
systemctl start mongod
EOF

  tags = {
    Name = "Backend"
  }
}


#SSM-IAM-Role:

resource "aws_iam_role" "ssm_role" {
  name = "SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "SSMProfile"
  role = aws_iam_role.ssm_role.name
}

