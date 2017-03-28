# Run
# AWS_ACCESS_KEY=<key> AWS_SECRET_KEY=<key> terraform apply

# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "terraform_example_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "terraform_example"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All communication between members of the VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Access from the world while testing
  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "database" {
  connection {
    user        = "centos"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
  tags {
    Name = "Database"
  }
  instance_type          = "t2.small"
  ami                    = "${lookup(var.aws_amis, var.aws_region)}"
  key_name               = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  subnet_id              = "${aws_subnet.default.id}"
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld",
      "sudo yum update -y",
      "sudo yum install -y mariadb-server",
      "sudo systemctl enable mariadb",
      "sudo systemctl start mariadb",
      "curl -o /tmp/datastore_creation_script.sql ${var.database_creation_script}",
      "sudo mysql < /tmp/datastore_creation_script.sql",
   ]
  }
}

resource "aws_instance" "node_cluster" {
  connection {
    user        = "centos"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
  tags {
    Name = "App server"
  }
  count                  = 1
  instance_type          = "t2.small"
  ami                    = "${lookup(var.aws_amis, var.aws_region)}"
  key_name               = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  subnet_id              = "${aws_subnet.default.id}"

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld",
      "sudo yum update -y",
      "sudo yum install -y epel-release",
      "sudo yum install -y git",
      "sudo yum install -y nodejs",
      "git clone ${var.node_repo_url} app",
      "cd app",
      "npm --no-color install",
      "export DB_HOST=${aws_instance.database.private_ip}",
      "export DB_PORT=3306",
      "export DB_USER=brooklyn",
      "export DB_PASSWORD=br00k11n",
      "export DB_NAME=todo",
      # TODO: Convince Terraform/something that the process shouldn't die when the provisioner exits.
      "nohup node ${var.node_app_filename} >console.log 2>&1 & disown",
      # Attempt to solve the exit per the only recommendation I could find on the matter.
      # Doesn't seem to help.
      "sleep 3"
    ]
  }
}

resource "aws_elb" "web" {
  name = "terraform-example-elb"

  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.node_cluster.id}"]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 15
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

