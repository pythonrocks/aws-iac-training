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

output "instance_ip_addr" {
  value = aws_instance.hw5.public_ip
}

output "sqs_queue_url" {
  value = aws_sqs_queue.hw5_queue.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.hw5_topic.arn
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_iam_role" "ec2_iam_role" {
  name               = "ec2_iam_role"
  assume_role_policy = file("role.json")
}

resource "aws_iam_role_policy" "ec2_iam_role_policy" {
  name   = "ec2_iam_role_policy"
  role   = aws_iam_role.ec2_iam_role.id
  policy = file("policy.json")
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_iam_role.name
}

resource "aws_security_group" "hw5_sg" {
  name = "hw5-sg"

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

resource "aws_instance" "hw5" {
  ami                  = var.image_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  security_groups      = [aws_security_group.hw5_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.id

  tags = {
    Name = "HW-5"
  }
}

resource "aws_sqs_queue" "hw5_queue" {
  name                      = "hw5-queue"
  max_message_size          = 2048
  message_retention_seconds = 60
  receive_wait_time_seconds = 10

  tags = {
    Name = "hw5"
  }
}

resource "aws_sns_topic" "hw5_topic" {
  name = "hw5-topic"
}
