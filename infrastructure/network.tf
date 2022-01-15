
locals {
  vpc_cidr = "10.0.0.0/16" # TODO: smaller/better than this
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
}

resource "aws_subnet" "main" {
  availability_zone       = "ap-southeast-2a" # who needs redundancy?
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.vpc_cidr
  map_public_ip_on_launch = true
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 7777
    to_port     = 7777
  }

  ingress {
    self      = true
    protocol  = -1
    from_port = 0
    to_port   = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = -1
    from_port   = 0
    to_port     = 0
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "gateway" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}
