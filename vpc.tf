provider "aws" {
  region  = "ap-south-1"
  profile = "shashikant"
}



resource "aws_vpc" "shashikant_vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames  = true

  tags = {
    Name = "shashikant_vpc"
  }
}



resource "aws_subnet" "shashikant_public_subnet" {
  vpc_id     = aws_vpc.shashikant_vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "shashikant_public_subnet"
  }
}



resource "aws_subnet" "shashikant_private_subnet" {
  vpc_id     = aws_vpc.shashikant_vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "shashikant_private_subnet"
  }
}



resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.shashikant_vpc.id

  tags = {
    Name = "my_internet_gateway"
  }
}



resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.shashikant_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "my_route_table"
  }
}



resource "aws_route_table_association" "assign_route_table_topublic" {
  subnet_id      = aws_subnet.shashikant_public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
} 



resource "aws_security_group" "webserver_security_group" {
  name        = "webserver_security_group"
  description = "Allow ssh and http"
  vpc_id      = aws_vpc.shashikant_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver_security_group"
  }
}



resource "aws_security_group" "database_security_group" {
  name        = "database_security_group"
  description = "Allow MYSQL"
  vpc_id      = aws_vpc.shashikant_vpc.id

  ingress {
    description = "MYSQL"
    security_groups = [aws_security_group.webserver_security_group.id]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database_security_group"
  }
}



resource "aws_instance" "wordpress" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.shashikant_public_subnet.id
  vpc_security_group_ids = [aws_security_group.webserver_security_group.id]
  key_name = "mykey"

  tags = {
		Name = "wordpress"
  }
}



resource "aws_instance" "MySQL" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.shashikant_private_subnet.id
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  key_name = "mykey"
  
  tags = {
    Name = "MySQL"
  }
}