resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "prod-vpc"
    Purpose = "Jenkins Demo"
  }
}

resource "aws_internet_gateway" "ig"{
  vpc_id  = aws_vpc.vpc.id
  tags = {
    Name = "prod-ig"
  }
}



#3.create custom route table

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "Prod-route-table"
  }
}

# 4.create a subnet

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = ap-south-1a

  tags = {
    Name = "prod-subnet"
  }
}

# 5.associate subnet wit route table 

resource "aws_route_table_association" "asso
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}


# 6.create a security group with port 22,80,443
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


# 7.create a nework interface with an ip that was associated with subnet at step4
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls.id]
}


# 8.assign a elistic ip for the ni that for step 7

resource "aws_eip" "eip"{
  vpc                       = true
  network_interface         = aws_network_interface.nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.ig]
}


# 9.create ubuntu server and install/enable apache


resource "aws_instance" "web_server_instance" {
  ami               = "ami-0851b76e8b1bce90b"
  instance_type     = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name          = "main-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  }
}

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_Web"
  }
}
