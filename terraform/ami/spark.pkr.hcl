
variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "spark" {
  ami_name                    = "spark-${local.timestamp}"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  region                      = var.aws_region
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  # Ubuntu 18
  source_ami   = "ami-013f17f36f8b1fefb"
  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.spark"]
}