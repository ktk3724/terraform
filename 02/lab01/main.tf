# provider 설정
provider "aws" {
  region = "us-east-2"  # 사용하고자 하는 AWS 리전으로 변경
}
# vpc 생성
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "myVPC" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "myVPC"
  }
}
# Internet Gateway 생성
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "main"
  }
}
# public subet 생성
resource "aws_subnet" "mypubsubet" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "mypubsubet"
  }
}

# public Routing Table 생성 & public subnet에 연결
resource "aws_route_table" "mypubrt" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }


  tags = {
    Name = "mypubrt"
  } 
}
resource "aws_route_table_association" "mypublicassociation" {
  subnet_id      = aws_subnet.mypubsubet.id
  route_table_id = aws_route_table.mypubrt.id
}


##############

# security group 생성
resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow 8080 inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "my_allow_8080"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_8080_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# EC2 생성
resource "aws_instance" "example1" {
  ami           = "ami-0d7ae6a161c5c4239"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  

  subnet_id = aws_subnet.mypubsubet.id
  # 보안 그룹을 새로 생성한 보안 그룹으로 수정
  vpc_security_group_ids = [aws_security_group.allow_8080.id]

  user_data_replace_on_change = true
  user_data = <<-EOF
    # !/bin/bash
    echo "Hello world" > /var/www/html/index.html
    systemctl enable --now httpd
    EOF

  tags = {
    Name = "test1"
  }
}
