variable "vpc_name" {
  default = "final"
}

variable "cidr_public_block_1" {
  default = "10.0.1.0/24"
}

variable "cidr_public_block_2" {
  default = "10.0.2.0/24"
}

variable "cidr_private_block_1" {
  default = "10.0.3.0/24"
}

variable "cidr_private_block_2" {
  default = "10.0.4.0/24"
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

variable "s3_bucket" {
  type    = string
  default = "s3://aws-training-pythonrocks-20210430"
}

output "rds_endpoint" {
  value = aws_db_instance.rds_pgsql.endpoint
}

output "elb_dns_name" {
  value = aws_elb.elb.dns_name
}

output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}
