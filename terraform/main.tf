provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "spark" {

  description = "Standalone Spark cluster"
  vpc_id      = var.aws_vpc_id

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
}

resource "aws_key_pair" "spark" {
  public_key = file(var.public_key_path)
}

resource "aws_instance" "master" {
  ami                         = var.aws_ami
  instance_type               = var.master_instance_type
  subnet_id                   = var.aws_subnet_id
  vpc_security_group_ids      = [aws_security_group.spark.id]
  key_name                    = aws_key_pair.spark.key_name
  associate_public_ip_address = true
  # user_data                   = data.template_cloudinit_config.config.rendered

  tags = {
    Name = "spark-master"
  }

  root_block_device {
    volume_size = var.master_root_vol_size
  }
}

# TODO: Name tag?
resource "aws_spot_instance_request" "worker" {
  ami                         = var.aws_ami
  instance_type               = var.worker_instance_type
  subnet_id                   = var.aws_subnet_id
  vpc_security_group_ids      = [aws_security_group.spark.id]
  key_name                    = aws_key_pair.spark.key_name
  spot_price                  = var.worker_spot_price
  spot_type                   = "one-time"
  associate_public_ip_address = true
  wait_for_fulfillment        = true
  count                       = var.worker_count
  # user_data                   = data.template_cloudinit_config.config.rendered

  root_block_device {
    volume_size = var.worker_root_vol_size
  }
}

locals {
  template_dir   = "${path.module}/templates"
  ansible_dir    = "${path.module}/.ansible"
  spark_conf_dir = "${local.ansible_dir}/conf"
}

resource "local_file" "inventory" {
  filename = "${local.ansible_dir}/inventory"

  content  = templatefile("${local.template_dir}/inventory.tpl", {
    master_ip             = aws_instance.master.public_ip
    master_private_ip     = aws_instance.master.private_ip
    worker_ips            = join("\n", [for ip in aws_spot_instance_request.worker.*.public_ip : ip if ip != null])
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    docker_image          = var.docker_image
  })

  # Wait for assigned IPs to be known, before writing inventory.
  depends_on = [
    aws_instance.master,
    aws_spot_instance_request.worker,
  ]
}

resource "local_file" "spark_defaults" {
  filename = "${local.spark_conf_dir}/spark-defaults.conf"

  content  = templatefile("${local.template_dir}/spark-defaults.conf.tpl", {
    master_private_ip      = aws_instance.master.private_ip
    driver_memory          = var.driver_memory
    executor_memory        = var.executor_memory
    max_driver_result_size = var.max_driver_result_size
    max_task_failures      = var.max_task_failures
    max_s3_connections     = var.max_s3_connections
    packages               = join(",", var.spark_packages)
  })
}

resource "local_file" "spark_env" {
  filename = "${local.spark_conf_dir}/spark-env.sh"

  content  = templatefile("${local.template_dir}/spark-env.sh.tpl", {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    max_files             = var.max_files
    openblas_num_threads  = var.openblas_num_threads
  })
}

resource "local_file" "log4j" {
  content  = file("${local.template_dir}/log4j.properties")
  filename = "${local.spark_conf_dir}/log4j.properties"
}

resource "local_file" "docker_bash" {
  content  = file("${local.template_dir}/docker-bash.sh")
  filename = "${local.ansible_dir}/docker-bash.sh"
}

output "master_ip" {
  value = aws_instance.master.public_ip
}