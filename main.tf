# Create a VPC
resource "aws_vpc" "ecommerce_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecommerce-vpc"
  }
}

# Create a security group for the web server
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.ecommerce_vpc.id
  name   = "webserverSG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-webserver-sg"
  }
}

# Create a security group for the database server
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.ecommerce_vpc.id
  name   = "DBServerSG"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Only web server can access DB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-dbserver-sg"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "ecommerce-public-subnet"
  }
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.ecommerce_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "ecommerce-private-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  tags = {
    Name = "ecommerce-internet-gateway"
  }
}

# Create a NAT Gateway Elastic IP
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "ecommerce-nat-gateway"
  }
}

# Create a Route Table for the public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ecommerce-public-route-table"
  }
}

# Associate the public route table with the public subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a Route Table for the private subnet (for NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "ecommerce-private-route-table"
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Web Server EC2 Instance (Public)
resource "aws_instance" "web_server" {
  ami                    = "ami-023a307f3d27ea427"
  instance_type          = "t2.micro"
  key_name               = "keypair"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "tf-ecommerce-webserver"
  }
}

# Database Server EC2 Instance (Private)
resource "aws_instance" "db_server" {
  ami                    = "ami-023a307f3d27ea427"
  instance_type          = "t2.micro"
  key_name               = "keypair"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "tf-ecommerce-dbserver"
  }
}
