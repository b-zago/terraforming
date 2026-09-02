terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.additional_tags, {
    "Name" : var.vpc_name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.additional_tags, {
    "Name" : var.vpc_name
  })
}



###--- PUBLIC SUBNET ---###


resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az


  tags = merge(var.additional_tags, {
    "Name" : "${var.vpc_name}-${each.key}"
  })

}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.additional_tags, {
    "Name" : "${var.vpc_name}-public"
  })
}

resource "aws_route_table_association" "public_association" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}


###--- PRIVATE SUBNET ---###

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az


  tags = merge(var.additional_tags, {
    "Name" : "${var.vpc_name}-${each.key}"
  })
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = merge(var.additional_tags, {
    "Name" : "${var.vpc_name}-private"
  })
}

resource "aws_route_table_association" "private_association" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_nat_gateway" "this" {
  count = length(var.private_subnets) > 0 ? 1 : 0

  allocation_id = aws_eip.this[0].id
  subnet_id     = aws_subnet.public[var.nat_subnet_key].id

  depends_on = [aws_internet_gateway.this]

  tags = merge(var.additional_tags, {
    "Name" : var.vpc_name
  })
}

resource "aws_eip" "this" {
  count  = length(var.private_subnets) > 0 ? 1 : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.this]

  tags = merge(var.additional_tags, {
    "Name" : var.vpc_name
  })
}

