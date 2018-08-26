resource "aws_instance" "master" {
  ami                         = "${var.base_ami}"
  instance_type               = "${var.master_instance_type}"
  subnet_id                   = "${aws_subnet.spark.id}"
  vpc_security_group_ids      = ["${aws_security_group.spark-spark.id}"]
  key_name                    = "${aws_key_pair.spark.id}"
  associate_public_ip_address = true

  tags {
    Name = "spark-master"
  }
}

resource "aws_instance" "worker" {
  ami                         = "${var.base_ami}"
  instance_type               = "${var.worker_instance_type}"
  subnet_id                   = "${aws_subnet.spark.id}"
  vpc_security_group_ids      = ["${aws_security_group.spark-spark.id}"]
  key_name                    = "${aws_key_pair.spark.id}"
  associate_public_ip_address = true

  count = "${var.worker_count}"

  tags {
    Name = "spark-worker"
  }
}

data "template_file" "inventory" {
  template = "${file("${path.module}/inventory.tpl")}"

  vars {
    master_ip              = "${aws_instance.master.public_ip}"
    worker_ips             = "${join("\n", aws_instance.worker.*.public_ip)}"
    aws_region             = "${var.aws_region}"
    master_private_dns     = "${aws_instance.master.private_dns}"
    first_worker_id        = "${aws_instance.worker.0.id}"
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

output "master_ip" {
  value = "${aws_instance.master.public_ip}"
}
