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

variable "s3_bucket" {
  type = string
  default = "s3://aws-training-mkrysiuk-1616407765"
}

variable "s3_prefix" {
  type = string
  default = "testfile.txt"
}


output "instance_ip_addr" {
  value = aws_instance.hw3.public_ip
}

data "template_file" "init" {
  template = file("user-data.sh.tpl")

  vars = {
    s3_bucket = var.s3_bucket
    s3_prefix = var.s3_prefix
  }
}


resource "aws_iam_role" "ec2_iam_role" {
    name = "ec2_iam_role"
    assume_role_policy = file("role.json")
}

resource "aws_iam_role_policy" "ec2_iam_role_policy" {
  name = "ec2_iam_role_policy"
  role = aws_iam_role.ec2_iam_role.id
  policy = file("policy.json")
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "ec2_instance_profile"
    role = aws_iam_role.ec2_iam_role.name
}

resource "aws_security_group" "hw3_sg" {
  name = "hw3-sg"

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

resource "aws_instance" "hw3" {
  ami           = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.hw3_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.id

  user_data = data.template_file.init.rendered

  tags = {
    Name = "HW-3"
  }
}