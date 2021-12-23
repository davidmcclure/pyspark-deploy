variable "aws_region" {
  type = string
}

variable "aws_availability_zone" {
  type = string
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
}

variable "worker_instance_type" {
  type = string
}

variable "worker_spot_price" {
  type = number
}

variable "public_key_path" {
  type = string
}

variable "on_demand_worker_count" {
  type = number
}

variable "spot_worker_count" {
  type = number
}

variable "master_root_vol_size" {
  type = number
}

variable "worker_root_vol_size" {
  type = number
}
