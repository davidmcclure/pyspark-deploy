module "vpc" {
  source = "../modules/vpc"
}

provider "aws" {
  region = "${module.vpc.aws_region}"
}

resource "aws_security_group" "docker" {
  name        = "${var.name}"
  description = "Docker AMI"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  egress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  egress {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  tags {
    Name = "${var.name}"
  }
}

resource "aws_instance" "docker" {
  ami                         = "${var.base_ami}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${module.vpc.subnet_id}"
  vpc_security_group_ids      = ["${aws_security_group.docker.id}"]
  key_name                    = "${module.vpc.key_name}"
  associate_public_ip_address = true

  tags {
    Name = "${var.name}"
  }
}

data "template_file" "inventory" {
  template = "${file("${path.module}/inventory.tpl")}"

  vars {
    docker_ip = "${aws_instance.docker.public_ip}"
  }
}

resource "local_file" "inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "${path.module}/../.inventory/docker-ami"
}
