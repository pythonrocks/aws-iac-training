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

resource "aws_vpc" "final" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.final.id
}

resource "aws_subnet" "public_subnet_1" {
  availability_zone       = "us-west-2a"
  cidr_block              = var.cidr_public_block_1
  vpc_id                  = aws_vpc.final.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  availability_zone       = "us-west-2b"
  cidr_block              = var.cidr_public_block_2
  vpc_id                  = aws_vpc.final.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet_1" {
  availability_zone       = "us-west-2a"
  cidr_block              = var.cidr_private_block_1
  vpc_id                  = aws_vpc.final.id
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_subnet_2" {
  availability_zone       = "us-west-2b"
  cidr_block              = var.cidr_private_block_2
  vpc_id                  = aws_vpc.final.id
  map_public_ip_on_launch = false
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.final.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "public_1" {

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "public_2" {

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_subnet_2.id
}

resource "aws_security_group" "ssh_web" {
  vpc_id = aws_vpc.final.id

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

  vpc_id = aws_vpc.final.id

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
    cidr_blocks = [aws_subnet.private_subnet_1.cidr_block, aws_subnet.private_subnet_2.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [aws_subnet.private_subnet_1.cidr_block, aws_subnet.private_subnet_2.cidr_block]
  }
}

resource "aws_instance" "bastion" {
  subnet_id              = aws_subnet.public_subnet_1.id
  ami                    = var.image_id
  vpc_security_group_ids = [aws_security_group.ssh_web.id]
  instance_type          = var.instance_type
  key_name               = var.key_name

  tags = {
    Name = "bastion"
  }
}

data "template_file" "init" {
  template = file("setup_private.sh")

  vars = {
    rds_host = aws_db_instance.rds_pgsql.address
  }
}

resource "aws_instance" "priv_instance" {
  subnet_id              = aws_subnet.private_subnet_1.id
  ami                    = var.image_id
  vpc_security_group_ids = [aws_security_group.ssh_web.id]
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data            = data.template_file.init.rendered
  depends_on           = [aws_instance.nat, aws_db_instance.rds_pgsql]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  tags = {
    Name = "private"
  }
}

resource "aws_instance" "nat" {
  ami                         = "ami-0553ff0c22b782b45"
  instance_type               = "t2.micro"
  source_dest_check           = false
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.nat_sec_group.id]

  tags = {
    Name = "NAT"
  }
}

resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.final.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat.id
  }

}

resource "aws_route_table_association" "private_subnet_to_nat_instance" {
  route_table_id = aws_route_table.nat_rt.id
  subnet_id      = aws_subnet.private_subnet_1.id
}

resource "aws_sns_topic" "sns_topic" {
  name = "edu-lohika-training-aws-sns-topic"
}


resource "aws_launch_template" "asg_lt" {
  name                   = "asg_lc"
  image_id               = var.image_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ssh_web.id]
  user_data              = filebase64("setup_public.sh")
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "public"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "asg"
  max_size            = 2
  min_size            = 2
  desired_capacity    = 2
  force_delete        = true
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  load_balancers      = [aws_elb.elb.name]

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_elb" "elb" {
  name            = "elb"
  subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
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
    target              = "HTTP:80/actuator/health"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 300
}

resource "aws_dynamodb_table" "final_hw" {
  name           = "edu-lohika-training-aws-dynamodb"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "UserName"

  attribute {
    name = "UserName"
    type = "S"
  }

}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.final.id
  service_name = "com.amazonaws.us-west-2.dynamodb"
}

resource "aws_security_group" "rds_sg" {
  name   = "rds_access"
  vpc_id = aws_vpc.final.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.cidr_private_block_1]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds_subnet"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

resource "aws_db_instance" "rds_pgsql" {
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "12.5"
  instance_class    = "db.t2.micro"
  name              = "EduLohikaTrainingAwsRds"
  username          = "rootuser"
  password          = "rootuser"

  db_subnet_group_name    = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  backup_retention_period = 0
  apply_immediately       = true

  tags = {
    Name = "db"
  }
}

resource "aws_iam_role" "god_role" {
  name               = "god_role"
  assume_role_policy = file("role.json")
}

resource "aws_iam_role_policy" "god_role" {
  name   = "god_role"
  role   = aws_iam_role.god_role.id
  policy = file("policy.json")
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.god_role.name
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.final.id
  service_name = "com.amazonaws.us-west-2.s3"
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.final.id
  service_name        = "com.amazonaws.us-west-2.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids  = [aws_security_group.ssh_web.id]
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.final.id
  service_name        = "com.amazonaws.us-west-2.sns"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids  = [aws_security_group.ssh_web.id]
}

resource "aws_vpc_endpoint_route_table_association" "nat_to_s3" {
  route_table_id  = aws_route_table.nat_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "public_to_dynamo" {
  route_table_id  = aws_route_table.public.id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
}

resource "aws_sqs_queue" "sqs_queue" {
  name                      = "edu-lohika-training-aws-sqs-queue"
  max_message_size          = 2048
  message_retention_seconds = 60
  receive_wait_time_seconds = 10

  tags = {
    Name = "sqs-queue"
  }
}
