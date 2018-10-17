output "aws_region" {
  value = "${var.aws_region}"
}

output "vpc_id" {
  value = "${aws_vpc.spark.id}"
}

output "subnet_id" {
  value = "${aws_subnet.spark.id}"
}

output "key_name" {
  value = "${aws_key_pair.spark.key_name}"
}

output "inventory_dir" {
  value = "${path.module}/../../ansible/.inventory"
}
