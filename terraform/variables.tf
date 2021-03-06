variable "aws_region" {
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
  default = "c5.xlarge"
}

variable "worker_instance_type" {
  default = "c3.4xlarge"
}

variable "worker_spot_price" {
  default = 0.4
}

variable "worker_count" {
  default = 1
}

variable "public_key_path" {
  default = "~/.ssh/spark.pub"
}

variable "master_root_vol_size" {
  default = 10
}

variable "worker_root_vol_size" {
  default = 100
}

variable "driver_memory" {
  default = "5g"
}

variable "executor_memory" {
  default = "20g"
}

variable "max_task_failures" {
  default = 20
}

variable "max_s3_connections" {
  default = 2000
}

variable "max_driver_result_size" {
  default = "10g"
}

variable "spark_packages" {
  default = [
    "org.apache.hadoop:hadoop-aws:2.7.3",
  ]
}

variable "max_files" {
  default = 100000
}

variable "openblas_num_threads" {
  default = 1
}

variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
}

variable "docker_image" {
  type = string
}