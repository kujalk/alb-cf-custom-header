#VPC creation
resource "aws_vpc" "main" {
  cidr_block       = var.VPC_CIDR
  instance_tenancy = "default"

  tags = {
    Name = "${var.Project}-VPC"
  }
}

#Creating a subnet-1
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.Subnet_CIDR1
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.Project}-PublicSubnet1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.Subnet_CIDR2
  availability_zone       = var.availability_zone2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.Project}-PublicSubnet2"
  }
}

resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.Subnet_CIDR3
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.Project}-PrivateSubnet1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.Subnet_CIDR4
  availability_zone       = var.availability_zone2
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.Project}-PrivateSubnet2"
  }
}

#Create IWG
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.Project}-IGW"
  }
}

#Route Table creation
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.Project}-PublicRT"
  }
}

#Associate the Route table with Subnet
resource "aws_route_table_association" "public-route1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "public-route2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.main.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [
    aws_internet_gateway.main
  ]
}

#Private subnet
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id
}

#Route Table creation
resource "aws_route_table" "main2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "${var.Project}-PrivateRT"
  }
}

resource "aws_route_table_association" "private-route1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.main2.id
}

resource "aws_route_table_association" "private-route2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.main2.id
}