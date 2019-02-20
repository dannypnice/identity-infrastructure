# Private subnet with a backend with "db" instance
# and a public subnet with 2 Windows "webserver" instances

# General setup

provider "aws" {
  region = "${var.aws_region}"
}

# Key pairs

resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = "${file(var.public_key)}"
}

# VPC setup

resource "aws_vpc" "vpc" {
  cidr_block = "10.10.0.0/16"

  tags {
    Name = "vpc"
  }
}

# Private and public subnets inside a vpc

resource "aws_subnet" "subnet_public" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.10.0.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public"
  }
}

resource "aws_subnet" "subnet_private" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "10.10.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "subnet-private"
  }
}

# Internet gateway

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "internet_gateway"
  }
}

# NAT gateway

resource "aws_eip" "nat_primary" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway_primary" {
  allocation_id = "${aws_eip.nat_primary.id}"
  subnet_id     = "${aws_subnet.subnet_public.id}"
}

# Subnet route tables

resource "aws_route_table" "route_table_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags {
    Name = "route-table-public"
  }
}

resource "aws_route_table_association" "route_table_assoc_public" {
  subnet_id      = "${aws_subnet.subnet_public.id}"
  route_table_id = "${aws_route_table.route_table_public.id}"
}

resource "aws_route_table" "route_table_private" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat_gateway_primary.id}"
  }

  tags {
    Name = "route-table-private"
  }
}

resource "aws_route_table_association" "route_table_private" {
  subnet_id      = "${aws_subnet.subnet_private.id}"
  route_table_id = "${aws_route_table.route_table_private.id}"
}

# Subnet network ACLs

resource "aws_network_acl" "acl_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  subnet_ids = [
    "${aws_subnet.subnet_public.id}",
  ]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "udp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 5060
    to_port    = 5061
  }

  ingress {
    protocol   = "udp"
    rule_no    = 150
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 10000
    to_port    = 20000
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.10.1.0/24"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags {
    Name = "acl-public"
  }
}

resource "aws_network_acl" "wn_private" {
  vpc_id = "${aws_vpc.vpc.id}"

  subnet_ids = [
    "${aws_subnet.subnet_private.id}",
  ]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/24"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.10.0.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  tags {
    Name = "acl-private"
  }
}

# Security groups

resource "aws_security_group" "webserver" {
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${aws_security_group.db.id}"]
  }

  tags = {
    Name = "webserver-SG"
  }
}

resource "aws_security_group" "db" {
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-SG"
  }
}

resource "aws_security_group" "ssh" {
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-SG"
  }
}

# Servers in private subnet

# fake db server

data "aws_ami" "ubuntu_base_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Lookup the correct AMI based on the region specified
data "aws_ami" "amazon_windows_2016" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base*"]
  }
}

resource "aws_instance" "db" {
  count         = 1
  ami           = "${data.aws_ami.ubuntu_base_ami.id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnet_private.id}"

  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.db.id}",
  ]

  key_name   = "${aws_key_pair.key.key_name}"
  depends_on = ["aws_internet_gateway.internet_gateway"]

  tags {
    Name = "db-0${count.index + 1}"
  }
}

# Servers in public subnet

#resource "aws_instance" "webserver" {
#  count         = 1
#  ami           = "${data.aws_ami.ubuntu_base_ami.id}"
#  instance_type = "t2.micro"
#  subnet_id     = "${aws_subnet.subnet_public.id}"

#  vpc_security_group_ids = [
#    "${aws_security_group.ssh.id}",
#    "${aws_security_group.webserver.id}",
#  ]

#  key_name   = "${aws_key_pair.key.key_name}"
#  depends_on = ["aws_internet_gateway.internet_gateway"]

#  tags {
#    Name = "webserver-0${count.index + 1}"
#  }
#}

resource "aws_instance" "webserver" {
  count         = "${var.count}"
  ami           = "${data.aws_ami.amazon_windows_2016.id}"
  instance_type = "t2.medium"
  subnet_id     = "${aws_subnet.subnet_public.id}"

  vpc_security_group_ids = [
    "${aws_security_group.webserver.id}",
  ]

  key_name   = "${aws_key_pair.key.key_name}"
  depends_on = ["aws_internet_gateway.internet_gateway"]

  #  user_data = <<EOF
  #<powershell>
  #Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature
  #</powershell>
  #EOF

  tags {
    Name = "webserver-0${count.index + 1}"
  }
}
