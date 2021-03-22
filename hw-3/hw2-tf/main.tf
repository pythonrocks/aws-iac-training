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
  type    = string
  default = "ami-00f9f4069d04c0c6e"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type    = string
  default = "test"
}

resource "aws_security_group" "hw2_sg" {
  name = "hw2-sg"

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
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "hw2_lc" {
  name_prefix = "hw2_lc-"

  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name

  security_groups = [aws_security_group.hw2_sg.id]
  associate_public_ip_address      = true

  user_data = file("user-data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "hw2_asg" {
  name                 = "hw2-asg"
  launch_configuration = aws_launch_configuration.hw2_lc.name
  min_size             = 2
  max_size             = 2
  availability_zones   = ["us-west-2a", "us-west-2b"]

  lifecycle {
    create_before_destroy = true
  }
}
