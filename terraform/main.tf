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

  tags = {
    Name = "spark-master"
  }

  root_block_device {
    volume_size = var.master_root_vol_size
  }
}

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

  root_block_device {
    volume_size = var.worker_root_vol_size
  }
}

data "template_file" "spark_defaults" {
  template = file("${path.module}/spark-defaults.conf.tpl")

  vars = {
    master_url             = aws_instance.master.public_ip
    driver_memory          = var.driver_memory
    executor_memory        = var.executor_memory
    max_driver_result_size = var.max_driver_result_size
    max_task_failures      = var.max_task_failures
    max_s3_connections     = var.max_s3_connections
    packages               = join(",", var.spark_packages)
  }

  depends_on = [
    aws_instance.master,
  ]
}

data "template_file" "spark_env" {
  template = file("${path.module}/spark-env.sh.tpl")

  vars = {
    aws_access_key_id = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    max_files = var.max_files
    openblas_num_threads = var.openblas_num_threads
  }
}

# data "template_file" "inventory" {
#   template = file("${path.module}/inventory.tpl")

#   vars = {
#     master_ip         = aws_instance.master.public_ip
#     master_private_ip = aws_instance.master.private_ip
#     worker_ips        = join("\n", [for ip in aws_spot_instance_request.worker.*.public_ip : ip if ip != null])
#   }

#   # Wait for assigned IPs to be known, before writing inventory.
#   depends_on = [
#     aws_instance.master,
#     aws_spot_instance_request.worker,
#   ]
# }

resource "local_file" "spark_defaults" {
  content  = data.template_file.spark_defaults.rendered
  filename = "${path.module}/spark-defaults.conf"
}

resource "local_file" "spark_env" {
  content  = data.template_file.spark_env.rendered
  filename = "${path.module}/spark-env.sh"
}