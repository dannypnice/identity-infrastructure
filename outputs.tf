# Output variables

# Since db resides in private subnet, this variable should be empty
output "db_public_ip" {
  value = "${aws_instance.db.public_ip}"
}

output "db_private_ip" {
  value = "${aws_instance.db.private_ip}"
}

output "webserver_public_ip" {
  value = "${aws_instance.webserver.*.public_ip}"
}
