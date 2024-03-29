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

resource "aws_instance" "worker" {
  ami                         = var.aws_ami
  instance_type               = var.worker_instance_type
  subnet_id                   = var.aws_subnet_id
  vpc_security_group_ids      = [aws_security_group.spark.id]
  key_name                    = aws_key_pair.spark.key_name
  associate_public_ip_address = true
  count                       = var.on_demand_worker_count

  root_block_device {
    volume_size = var.worker_root_vol_size
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
  count                       = var.spot_worker_count

  root_block_device {
    volume_size = var.worker_root_vol_size
  }
}

data "template_file" "inventory" {
  template = file("${path.module}/inventory.tpl")

  vars = {
    master_ip            = aws_instance.master.public_ip
    master_private_ip    = aws_instance.master.private_ip
    on_demand_worker_ips = join("\n", [for ip in aws_instance.worker.*.public_ip : ip if ip != null])
    spot_worker_ips      = join("\n", [for ip in aws_spot_instance_request.worker.*.public_ip : ip if ip != null])
  }

  # Wait for assigned IPs to be known, before writing inventory.
  depends_on = [
    aws_instance.master,
    aws_instance.worker,
    aws_spot_instance_request.worker,
  ]
}

resource "local_file" "inventory" {
  content  = data.template_file.inventory.rendered
  filename = "${path.module}/../ansible/inventory"
}

output "master_ip" {
  value = aws_instance.master.public_ip
}
