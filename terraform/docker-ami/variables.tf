variable "name" {
  default = "docker"
}

variable "base_ami" {
  default     = "ami-0ac019f4fcb7cb7e6"
  description = "Ubuntu 18"
}

variable "instance_type" {
  default = "t2.micro"
}
