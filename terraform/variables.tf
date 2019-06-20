variable "name" {
  default = "spark"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_availability_zone" {
  default = "us-east-1a"
}

variable "vpc_id" {
  type = "string"
}

variable "subnet_id" {
  type = "string"
}

variable "docker_ami" {
  type        = "string"
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

variable "driver_memory" {
  default = "5g"
}

variable "driver_max_result_size" {
  default = "10g"
}

variable "executor_memory" {
  default = "40g"
}

variable "worker_docker_runtime" {
  default = ""
}
