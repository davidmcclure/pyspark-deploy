resource "aws_vpc" "spark" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "${var.name}"
  }
}

resource "aws_internet_gateway" "spark" {
  vpc_id = "${aws_vpc.spark.id}"
}

resource "aws_subnet" "spark" {
  vpc_id            = "${aws_vpc.spark.id}"
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.aws_availability_zone}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_route_table" "spark" {
  vpc_id = "${aws_vpc.spark.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.spark.id}"
  }

  tags {
    Name = "${var.name}"
  }
}

resource "aws_route_table_association" "spark" {
  subnet_id      = "${aws_subnet.spark.id}"
  route_table_id = "${aws_route_table.spark.id}"
}

resource "aws_key_pair" "spark" {
  key_name   = "${var.name}"
  public_key = "${file("~/.ssh/spark.pub")}"
}
