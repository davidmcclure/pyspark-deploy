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

resource "aws_security_group" "spark-spark" {
  name        = "${var.name}-spark"
  description = "Standalone Spark cluster"
  vpc_id      = "${aws_vpc.spark.id}"

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
    Name = "${var.name}-spark"
  }
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
