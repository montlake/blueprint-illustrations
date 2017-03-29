output "elb" {
  value = "${aws_elb.web.dns_name}"
}
