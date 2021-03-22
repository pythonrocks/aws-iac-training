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

variable "image_id" {
  type = string
  default = "ami-00f9f4069d04c0c6e"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
  default = "test"
}

output "instance_ip_addr" {
  value = aws_instance.hw1.public_ip
}

resource "aws_security_group" "hw1_sg" {
  name = "hw1-sg"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "hw1" {
  ami           = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.hw1_sg.name]

  tags = {
    Name = "HW-1"
  }
}