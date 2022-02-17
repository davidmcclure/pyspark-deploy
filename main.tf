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

# TODO: Provision the subnet directly?
resource "aws_network_interface" "master" {
  subnet_id       = var.aws_subnet_id
  security_groups = [aws_security_group.spark.id]
}

locals {
  user_data_vars = {
    ecr_server             = var.ecr_server
    ecr_repo               = var.ecr_repo
    aws_access_key_id      = var.aws_access_key_id
    aws_secret_access_key  = var.aws_secret_access_key
    wandb_api_key          = var.wandb_api_key
    driver_memory          = var.driver_memory
    executor_memory        = var.executor_memory
    max_driver_result_size = var.max_driver_result_size
    spark_packages         = var.spark_packages
    data_dir               = var.data_dir
    max_task_failures      = var.max_task_failures
    master_private_ip      = aws_network_interface.master.private_ip
  }
}

locals {
  master_user_data = templatefile(
    "cloud-config.yaml",
    merge(local.user_data_vars, { master = true })
  )
  worker_user_data = templatefile(
    "cloud-config.yaml",
    merge(local.user_data_vars, { master = false })
  )
}

resource "aws_instance" "master" {
  ami           = var.aws_ami
  instance_type = var.master_instance_type
  key_name      = aws_key_pair.spark.key_name
  user_data     = local.master_user_data

  network_interface {
    network_interface_id = aws_network_interface.master.id
    device_index         = 0
  }

  root_block_device {
    volume_size = var.master_root_vol_size
  }

  tags = {
    Name = "spark-master"
  }
}

# TODO: Name tags on the workers.

resource "aws_instance" "workers" {
  ami                         = var.aws_ami
  instance_type               = var.worker_instance_type
  subnet_id                   = var.aws_subnet_id
  vpc_security_group_ids      = [aws_security_group.spark.id]
  key_name                    = aws_key_pair.spark.key_name
  associate_public_ip_address = true
  count                       = var.on_demand_worker_count
  user_data                   = local.worker_user_data

  root_block_device {
    volume_size = var.worker_root_vol_size
  }
}

resource "aws_spot_instance_request" "workers" {
  ami                         = var.aws_ami
  instance_type               = var.worker_instance_type
  subnet_id                   = var.aws_subnet_id
  vpc_security_group_ids      = [aws_security_group.spark.id]
  key_name                    = aws_key_pair.spark.key_name
  spot_price                  = var.spot_price
  associate_public_ip_address = true
  wait_for_fulfillment        = true
  count                       = var.spot_worker_count
  user_data                   = local.worker_user_data

  root_block_device {
    volume_size = var.worker_root_vol_size
  }
}

output "master_dns" {
  value = aws_instance.master.public_dns
}