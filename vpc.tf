resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "bhadram-vpc"
    Purpose = "Jenkins Demo"
  }
}

resource "aws_instance" "my_Server" {
  ami           = "ami-0851b76e8b1bce90b"
  instance_type = "t2.micro"
  tags = {
    Name = "ubuntu update"
  }
}
