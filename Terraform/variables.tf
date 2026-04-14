variable "aws_region" {
  default = "eu-west-1"
}

variable "instance_type" {
  default = "t3.small"
}

variable "ec2_ami" {
  default = "ami-0a8e758f5e873d1c1"
}

variable "bucket_name" {
  default = "my-terraform-s301-project-879515"
}

variable "key_name" {
  default = "Key-k8s"
}