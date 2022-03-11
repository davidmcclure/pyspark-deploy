
variable "ecr_server" {
  type = string
}

variable "ecr_repo" {
  type = string
}

# AWS

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_id" {
  type = string
}

# Deep Learning Base AMI (Ubuntu 18.04) Version 34.1
variable "aws_ami" {
  default = "ami-04eb5b2f5ef92e8b8"
}

variable "public_key_path" {
  default = "~/.ssh/spark.pub"
}

# Instances

variable "root_vol_size" {
  default = 100
}

variable "master_instance_type" {
  default = "c5.xlarge"
}

# TODO: Possible to automatically use, eg, 0.8 * instance ram?
variable "driver_memory" {
  default = "4g"
}

# TODO: Should these be grouped like this? Better way?
variable "on_demand_workers" {
  default = {
    count           = 0
    instance_type   = "c5.xlarge"
    executor_memory = "4g"
  }
}

variable "spot_workers" {
  default = {
    count           = 0
    instance_type   = "c5.xlarge"
    executor_memory = "4g"
    price           = 0.1
  }
}

# Config

variable "data_dir" {
  default = "/data"
}

variable "max_driver_result_size" {
  default = "10g"
}

variable "max_task_failures" {
  default = 20
}

variable "spark_packages" {
  default = [
    "org.apache.hadoop:hadoop-aws:3.2.0",
  ]
}

# Secrets

variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
}

variable "wandb_api_key" {
  default   = ""
  sensitive = true
}