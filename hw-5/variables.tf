variable "vpc_name" {
  default = "hw-5"
}

variable "cidr_public_block" {
  default = "10.0.1.0/24"
}

variable "cidr_private_block" {
  default = "10.0.2.0/24"
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

output "elb_dns_name" {
  value = aws_elb.hw_5_elb.dns_name
}
