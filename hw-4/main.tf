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
  default = "s3://aws-training-pythonrocks-20210401"
}

output "instance_ip_addr" {
  value = aws_instance.hw4.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.rds_pgsql.endpoint
}

output "rds_port" {
  value = aws_db_instance.rds_pgsql.port
}

data "template_file" "init" {
  template = file("user-data.sh.tpl")

  vars = {
    s3_bucket = var.s3_bucket
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
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

resource "aws_security_group" "hw4_sg" {
  name = "hw4-sg"

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

resource "aws_security_group" "rds_db" {
  name   = "rds_access"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds_subnet"
  subnet_ids = data.aws_subnet_ids.all.ids
}

resource "aws_instance" "hw4" {
  ami           = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.hw4_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.id

  user_data = data.template_file.init.rendered

  tags = {
    Name = "HW-4"
  }
}

resource "aws_dynamodb_table" "dynamodb_games" {
  name           = "games"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "title"
  range_key      = "publisher"

  attribute {
    name = "title"
    type = "S"
  }

  attribute {
    name = "publisher"
    type = "S"
  }
}

resource "aws_db_instance" "rds_pgsql" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.1"
  instance_class       = "db.t3.micro"
  name                 = "pgdb"
  username             = "hw4"
  password             = "foobarbaz"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.id
  vpc_security_group_ids = [aws_security_group.rds_db.id]
  skip_final_snapshot = true
  backup_retention_period = 0
  apply_immediately = true
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = data.aws_vpc.default.id
  service_name = "com.amazonaws.us-west-2.dynamodb"
}
