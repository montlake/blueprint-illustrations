# Run
# AWS_ACCESS_KEY=<key> AWS_SECRET_KEY=<key> terraform apply

# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "web" {
  name        = "terraform_example"
  description = "Used in the terraform"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Test
  ingress {
    from_port   = 8000
    to_port     = 8000
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

resource "aws_security_group" "database" {
  name        = "terraform_example_database"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 3306 to members of web
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
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
  vpc_security_group_ids = ["${aws_security_group.database.id}"]

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

data "template_file" "launch_node" {
  template = "${file("${path.module}/node-userdata.sh")}"
  vars {
    databaseIp = "${aws_instance.database.private_ip}"
    repoUrl    = "${var.node_repo_url}"
    repoScript = "${var.node_app_filename}"
  }
}

resource "aws_launch_configuration" "web-lc" {
  name          = "terraform-example-lc"
  image_id      = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.small"
  connection {
    user        = "centos"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  # Security group
  security_groups = ["${aws_security_group.web.id}"]
  user_data       = "${data.template_file.launch_node.rendered}"
  key_name        = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web-asg" {
  availability_zones   = ["${split(",", var.availability_zones)}"]
  name                 = "terraform-example-asg"
  max_size             = "5"
  min_size             = "1"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.web-lc.name}"
  load_balancers       = ["${aws_elb.web.name}"]
  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_policy" "web_scale_up" {
  name                     = "CPU scale up"
  scaling_adjustment       = 2
  adjustment_type          = "ChangeInCapacity"
  cooldown                 = 300
  autoscaling_group_name   = "${aws_autoscaling_group.web-asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "web_scale_up_metric" {
    alarm_name          = "Scale up from CPU"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = "1"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = "300"
    statistic           = "Average"
    threshold           = "65"
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.web-asg.name}"
    }
    alarm_description   = "Monitors auto-scaling group member CPU utilization"
    alarm_actions       = ["${aws_autoscaling_policy.web_scale_up.arn}"]
}

resource "aws_autoscaling_policy" "web_scale_down" {
  name                   = "CPU scale down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 600
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "web_scale_down_metric" {
    alarm_name          = "Scale down from CPU"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = "1"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = "600"
    statistic           = "Average"
    threshold           = "30"
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.web-asg.name}"
    }
    alarm_description   = "Monitors auto-scaling group member CPU utilization"
    alarm_actions       = ["${aws_autoscaling_policy.web_scale_down.arn}"]
}

resource "aws_elb" "web" {
  name = "app-elb"
  availability_zones   = ["${split(",", var.availability_zones)}"]

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
