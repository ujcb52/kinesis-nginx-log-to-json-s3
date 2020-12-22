resource "aws_vpc" "vpc_web1" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true

    tags = {
        Name = "vpc-web1"
    }
}

resource "aws_internet_gateway" "igw1" {
    vpc_id = aws_vpc.vpc_web1.id
}

/*
  Public Subnet
*/
resource "aws_subnet" "ap_northeast_2a_public" {
    vpc_id = aws_vpc.vpc_web1.id

    cidr_block = var.public_subnet_cidr
    availability_zone = "ap-northeast-2a"

    tags = {
        Name = "Public-Web-Subnet1"
    }
}

resource "aws_route_table" "ap_northeast_2a_public_rt" {
    vpc_id = aws_vpc.vpc_web1.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw1.id
    }

    tags = {
        Name = "Public-Web-Subnet1-RT"
    }
}

resource "aws_route_table_association" "ap-northeast-2a-public_asso" {
    subnet_id = aws_subnet.ap_northeast_2a_public.id
    route_table_id = aws_route_table.ap_northeast_2a_public_rt.id
}