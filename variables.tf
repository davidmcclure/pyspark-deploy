
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

variable "master_instance_type" {
  default = "c5.xlarge"
}

variable "worker_instance_type" {
  default = "c3.4xlarge"
}

variable "on_demand_worker_count" {
  default = 0
}

variable "spot_worker_count" {
  default = 0
}

variable "spot_worker_price" {
  default = 0.4
}

variable "gpu_workers" {
  default = false
}

variable "public_key_path" {
  default = "~/.ssh/spark.pub"
}

variable "master_root_vol_size" {
  default = 100
}

variable "worker_root_vol_size" {
  default = 100
}

variable "driver_memory" {
  default = "4g"
}

variable "executor_memory" {
  default = "4g"
}

variable "max_task_failures" {
  default = 20
}

variable "max_driver_result_size" {
  default = "10g"
}

variable "spark_packages" {
  default = [
    "org.apache.hadoop:hadoop-aws:3.2.0",
  ]
}

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

variable "data_dir" {
  default = "/data"
}

variable "ecr_server" {
  type = string
}

variable "ecr_repo" {
  type = string
}