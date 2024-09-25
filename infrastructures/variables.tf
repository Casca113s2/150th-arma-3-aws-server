variable "aws_region" {
  type    = string
  default = "ap-southeast-1" #Hong Kong
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ami_id" {
  type    = string
  default = "ami-01811d4912b4ccb26" # Singapore Ubuntu AMI
  # default = "ami-0d564a68f64a7542e" # HongKong Ubuntu AMI
}
