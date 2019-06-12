variable "name" {
  default = "spark"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_availability_zone" {
  default = "us-east-1a"
}

# TODO: Null value, in TF 0.12?
variable "docker_ami" {
  default     = "ami-XXX"
  description = "AMI with Docker."
}

variable "master_instance_type" {
  default = "c5.xlarge"
}

variable "worker_instance_type" {
  default = "c3.8xlarge"
}

variable "spot_price" {
  default = 0.48
}

variable "spot_type" {
  default = "one-time"
}

variable "worker_count" {
  default = 2
}

variable "master_root_vol_size" {
  default = 10
}

variable "worker_root_vol_size" {
  default = 10
}

variable "driver_memory" {
  default = "5g"
}

variable "driver_max_result_size" {
  default = "5g"
}

variable "executor_memory" {
  default = "40g"
}

