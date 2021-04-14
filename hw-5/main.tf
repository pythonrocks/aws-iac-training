terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_vpc" "hw_5" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.hw_5.id
}

resource "aws_subnet" "public_subnet" {
  availability_zone       = "us-west-2a"
  cidr_block              = var.cidr_public_block
  vpc_id                  = aws_vpc.hw_5.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  availability_zone       = "us-west-2b"
  cidr_block              = var.cidr_private_block
  vpc_id                  = aws_vpc.hw_5.id
  map_public_ip_on_launch = false
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hw_5.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "public" {

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_security_group" "ssh_web" {
  vpc_id = aws_vpc.hw_5.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nat_sec_group" {

  vpc_id = aws_vpc.hw_5.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_subnet.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [aws_subnet.private_subnet.cidr_block]
  }
}

resource "aws_instance" "pub_instance" {
  subnet_id              = aws_subnet.public_subnet.id
  ami                    = var.image_id
  vpc_security_group_ids = [aws_security_group.ssh_web.id]
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = file("setup_public.sh")
}


resource "aws_instance" "priv_instance" {
  subnet_id              = aws_subnet.private_subnet.id
  ami                    = var.image_id
  vpc_security_group_ids = [aws_security_group.ssh_web.id]
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = file("setup_private.sh")
  depends_on             = [aws_instance.nat]
}

resource "aws_instance" "nat" {
  ami                         = "ami-0553ff0c22b782b45"
  instance_type               = "t2.micro"
  source_dest_check           = false
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.nat_sec_group.id]

  tags = {
      Name = "NAT"
  }
}

resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.hw_5.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat.id
  }

}

resource "aws_route_table_association" "private_subnet_to_nat_instance" {
  route_table_id = aws_route_table.nat_rt.id
  subnet_id      = aws_subnet.private_subnet.id
}

resource "aws_elb" "hw_5_elb" {
  name            = "elb"
  subnets         = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
  security_groups = [aws_security_group.ssh_web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/index.html"
    interval            = 30
  }

  instances                   = [aws_instance.pub_instance.id, aws_instance.priv_instance.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 300
}
