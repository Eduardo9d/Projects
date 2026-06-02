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

variable "db" {
  type = object({
    name     = string
    username = string
    password = string
  })
  default = {
    name     = "mydb"
    username = "admin"
    password = "password"
  }
}

variable "allowed_ips" {
  description = "Additional IP ranges to allow access (e.g., office, VPN)"
  type        = list(string)
  default     = []
}