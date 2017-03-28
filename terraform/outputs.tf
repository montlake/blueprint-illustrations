output "addresses" {
  value = "http://${aws_instance.node_cluster.public_ip}:8000"
}

output "elb" {
  value = "${aws_elb.web.dns_name}"
}
