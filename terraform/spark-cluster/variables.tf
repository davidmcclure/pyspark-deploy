variable "name" {
  default = "spark"
}

variable "base_ami" {
  default = "ami-38708b45"
}

variable "master_instance_type" {
  default = "c5d.2xlarge"
}

variable "worker_instance_type" {
  default = "c5d.2xlarge"
}

variable "worker_count" {
  default = 2
}

variable "driver_memory" {
  default = "10g"
}

variable "driver_max_result_size" {
  default = "5g"
}

variable "executor_memory" {
  default = "10g"
}
