
variable "ecr_server" {
  type = string
}

variable "ecr_repo" {
  type = string
}

variable "driver_memory" {
  type = string
}

variable "executor_memory" {
  type = string
}

variable "max_driver_result_size" {
  type = string
}

variable "spark_packages" {
  type = list(string)
}

variable "data_dir" {
  type = string
}

variable "max_task_failures" {
  type = number
}

variable "master_private_ip" {
  type = string
  default = null
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
  type      = string
  sensitive = true
}