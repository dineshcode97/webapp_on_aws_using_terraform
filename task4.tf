provider "aws" {
region = "ap-south-1"
profile = "Dinesh"
}



resource "tls_private_key" "task4key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "genkey" {    
  key_name   = "task4key"
  public_key = "${tls_private_key.task4key.public_key_openssh}"


  depends_on = [
    tls_private_key.task4key
  ]
}

resource "local_file" "key-file" {
  content  = "${tls_private_key.task4key.private_key_pem}"
  filename = "task4key.pem"


  depends_on = [
    tls_private_key.task4key
  ]
}



resource "aws_vpc" "task4vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "task4vpc"
  }
}


resource "aws_security_group" "Dineshsg_wp" {
  name        = "Dineshsg_wp"
  description = "Allow HTTP inbound traffic"
  vpc_id      = "${aws_vpc.task4vpc.id}"


  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Dineshsg_wp"
  }
}



resource "aws_security_group" "Dineshsg_bastionhost" {
  name        = "Dineshsg_bastionhost"
  description = "ssh_bh"
  vpc_id      = "${aws_vpc.task4vpc.id}"


  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Dineshsg_bastionhost"
  }
}


resource "aws_security_group" "Dineshsg_mysql" {
  name        = "Dineshsg_mysql"
  description = "mysql"
  vpc_id      = "${aws_vpc.task4vpc.id}"


  ingress {
    description = "mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ "${aws_security_group.Dineshsg_bastionhost.id}" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "Dineshsg_mysql"
  }
}       


resource "aws_subnet" "Dineshsubnet_public" {
  vpc_id            = "${aws_vpc.task4vpc.id}"
  availability_zone = "ap-south-1a"
  cidr_block        = "192.168.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Dineshsubnet_public"
  }
}

resource "aws_internet_gateway" "Dinesh_ig" {
  vpc_id = "${aws_vpc.task4vpc.id}"
  tags = {
    Name = "Dinesh_ig"
  }
}
resource "aws_route_table" "Dinesh_route" {
  vpc_id = "${aws_vpc.task4vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.Dinesh_ig.id}"
  }
  tags = {
    Name = "Dinesh_route"
  }
}

resource "aws_route_table_association" "Dineshnata" {
  subnet_id      = aws_subnet.Dineshsubnet_public.id
  route_table_id = aws_route_table.Dinesh_route.id
}




resource "aws_subnet" "Dineshsubnet_private" {
  vpc_id            = "${aws_vpc.task4vpc.id}"
  availability_zone = "ap-south-1b"
  cidr_block        = "192.168.2.0/24"
  tags = {
    Name = "Dineshsubnet_private"
  }
}

resource "aws_eip" "elastic_ip" {
  vpc      = true
}


resource "aws_nat_gateway" "Dinesh_natgateway" {
  allocation_id = "${aws_eip.elastic_ip.id}"
  subnet_id     = "${aws_subnet.Dineshsubnet_public.id}"
  depends_on    = [ "aws_nat_gateway.Dinesh_natgateway" ]
}


resource "aws_route_table" "Dinesh_natgateway_route" {
  vpc_id = "${aws_vpc.task4vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.Dinesh_natgateway.id}"
  }
  tags = {
    Name = "Dinesh_natgateway_route"
  }
}
resource "aws_route_table_association" "natroute" {
  subnet_id      = aws_subnet.Dineshsubnet_private.id
  route_table_id = aws_route_table.Dinesh_natgateway_route.id
}




resource "aws_instance" "DineshWp_Os" {
  ami           = "ami-38146557 "
  instance_type = "t2.micro"
  key_name      = aws_key_pair.genkey.key_name
  subnet_id     = "${aws_subnet.Dineshsubnet_public.id}"
  vpc_security_group_ids = [ "${aws_security_group.Dineshsg_wp.id}" ]
  tags = {
    
    Name = "DineshWp_Os"
    
  }
}



resource "aws_instance" "Dinesh_Bashhost" {
  ami           = "ami-0ebc1ac48dfd14136"  
  instance_type = "t2.micro"
  key_name      = aws_key_pair.genkey.key_name
  subnet_id     = "${aws_subnet.Dineshsubnet_public.id}"
  vpc_security_group_ids = [ "${aws_security_group.Dineshsg_bastionhost.id}" ]
  tags = {
    
    Name = "Dinesh_BastionHost"
  }
}


resource "aws_instance" "Dinesh_MySql" {
  ami           = "ami-0b5bff6d9495eff69"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.genkey.key_name
  subnet_id     = "${aws_subnet.Dineshsubnet_private.id}"
  vpc_security_group_ids = [ "${aws_security_group.Dineshsg_mysql.id}" ]
  tags = {
    
    Name = "Dinesh_MySql"
  }
}