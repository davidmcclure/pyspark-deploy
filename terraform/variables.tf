variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_id" {
  type = string
}

variable "aws_ami" {
  type = string
}

variable "master_instance_type" {
  type = string
  default = "c5.xlarge"
}

variable "worker_instance_type" {
  type = string
  default = "c3.4xlarge"
}

variable "worker_spot_price" {
  type = number
  default = 0.4
}

variable "worker_count" {
  type = number
  default = 1
}

variable "public_key_path" {
  type = string
  default = "~/.ssh/spark.pub"
}

variable "master_root_vol_size" {
  type = number
  default = 10
}

variable "worker_root_vol_size" {
  type = number
  default = 100
}