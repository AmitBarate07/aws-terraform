resource "aws_vpc" "production" {

  cidr_block          = var.cidr
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  tags = merge(
    { "Name" = var.name }
  )
}
#################################public subnet

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  availability_zone                              = element(data.aws_availability_zones.available.names, count.index)
  cidr_block                                     = cidrsubnet(var.cidr, 4, count.index)
  enable_resource_name_dns_a_record_on_launch    = true
  vpc_id                                         = aws_vpc.production.id

  tags = merge(
    {
      Name = "public-subnet-${count.index+1}"
    }
  )
}

resource "aws_default_route_table" "production" {
  default_route_table_id = aws_vpc.production.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "IGW"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.production.id

  tags = merge(
    { "Name" = "IGW" }
  )
}
#################################Private subnet ####################
resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)
  availability_zone                              = element(data.aws_availability_zones.available.names, count.index)
  cidr_block                                     = cidrsubnet(var.cidr, 4, count.index + 3)
  enable_resource_name_dns_a_record_on_launch            = true
  vpc_id                                         = aws_vpc.production.id

  tags = merge(
    {
      Name = "private-subnet-${count.index+1}"
    }
  )
}


resource "aws_route_table" "private" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.production.id
}

resource "aws_route_table_association" "private" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(
    aws_route_table.private[*].id,count.index
  )
}

resource "aws_eip" "nat" {
  count = 1
  domain = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "this" {
  count = 1

  allocation_id = aws_eip.nat[0].id
  subnet_id = element(
    aws_subnet.public[*].id,count.index,
  )

depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "private_nat_gateway_RT" {
  count = length(data.aws_availability_zones.available.names)

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

}