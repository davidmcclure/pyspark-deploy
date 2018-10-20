variable "name" {
  default = "spark"
}

# TODO: Null value, in TF 0.12?
variable "docker_ami" {
  default     = "ami-XXX"
  description = "AMI with Docker."
}

variable "master_instance_type" {
  default = "c5.2xlarge"
}

variable "worker_instance_type" {
  default = "c5.9xlarge"
}

variable "spot_price" {
  default = 0.6
}

variable "spot_type" {
  default = "one-time"
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
