module "vpc" {
  source = "../vpc"
  name   = "${var.name}"
}

provider "aws" {
  region = "${module.vpc.aws_region}"
}

resource "aws_security_group" "spark" {
  name        = "${var.name}"
  description = "Standalone Spark cluster"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  egress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  egress {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  # All ports open intra-group, for Spark random assignment.
  ingress {
    from_port = 0
    to_port   = 65535
    self      = true
    protocol  = "tcp"
  }

  egress {
    from_port = 0
    to_port   = 65535
    self      = true
    protocol  = "tcp"
  }

  # Spark UI
  ingress {
    from_port   = 8080
    to_port     = 8081
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  # Spark UI "Application detail"
  ingress {
    from_port   = 4040
    to_port     = 4040
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  tags {
    Name = "${var.name}"
  }
}

resource "aws_instance" "master" {
  ami                         = "${var.docker_ami}"
  instance_type               = "${var.master_instance_type}"
  subnet_id                   = "${module.vpc.subnet_id}"
  vpc_security_group_ids      = ["${aws_security_group.spark.id}"]
  key_name                    = "${module.vpc.key_name}"
  associate_public_ip_address = true

  root_block_device = {
    volume_size = "${var.master_root_vol_size}"
  }

  tags {
    Name = "spark-master"
  }
}

# TODO: one-time
resource "aws_spot_instance_request" "worker" {
  ami                         = "${var.docker_ami}"
  instance_type               = "${var.worker_instance_type}"
  subnet_id                   = "${module.vpc.subnet_id}"
  vpc_security_group_ids      = ["${aws_security_group.spark.id}"]
  key_name                    = "${module.vpc.key_name}"
  spot_price                  = "${var.spot_price}"
  spot_type                   = "${var.spot_type}"
  associate_public_ip_address = true
  wait_for_fulfillment        = true

  root_block_device = {
    volume_size = "${var.worker_root_vol_size}"
  }

  count = "${var.worker_count}"
}

data "template_file" "inventory" {
  template = "${file("${path.module}/inventory.tpl")}"

  vars {
    master_ip              = "${aws_instance.master.public_ip}"
    worker_ips             = "${join("\n", aws_spot_instance_request.worker.*.public_ip)}"
    master_private_dns     = "${aws_instance.master.private_dns}"
    driver_memory          = "${var.driver_memory}"
    driver_max_result_size = "${var.driver_max_result_size}"
    executor_memory        = "${var.executor_memory}"
  }
}

resource "local_file" "inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "${path.module}/.inventory"
}

resource "local_file" "master_ip" {
  content  = "${aws_instance.master.public_ip}"
  filename = "${path.module}/.master-ip"
}
