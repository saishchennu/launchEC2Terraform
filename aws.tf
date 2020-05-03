provider "aws" {
  access_key = "XXXXXX"
  secret_key = "XXXXXXX""
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/26"
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  cidr_block = "10.0.0.0/28"
  availability_zone = "us-east-1c"
}

resource "aws_internet_gateway" "iw" {
  vpc_id = "${aws_vpc.my_vpc.id}"
}

resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.iw.id}"
  }
}

resource "aws_route_table_association" "public_route_assoc" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_instance" "ec2_server" {
  ami = "ami-0323c3dd2da7fb37d"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public.id}"
  associate_public_ip_address = "true"
  key_name = "sriawsKeypair"
  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install epel-release
              sudo yum -y install git 
              sudo amazon-linux-extras install ansible2
              sudo yum -y install nginx
              EOF
  vpc_security_group_ids = [
    "${aws_security_group.allow_ssh.id}"]
  tags = {
     stack =  "webservers"
  }
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  vpc_id = "${aws_vpc.my_vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}
