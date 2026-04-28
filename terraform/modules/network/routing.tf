# Creating a public route table for our VPC
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  tags = { Name = "public-rt-${var.env}" }
}

# Associating our public subnets (NAT and ALB) with the public route table
resource "aws_route_table_association" "nat_assoc" {
  subnet_id      = aws_subnet.public_subnet_nat.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "alb_assoc_1" {
  subnet_id      = aws_subnet.alb_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "alb_assoc_2" {
  subnet_id      = aws_subnet.alb_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Creating the NAT Gateway 
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_nat.id

  tags = { Name = "nat-gateway-${var.env}" }
}

# Create a Private Route Table 
resource "aws_route_table" "private_rt" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private-rt-${var.env}" }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.asg_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "db_assoc_1" {
  subnet_id      = aws_subnet.db_private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "db_assoc_2" {
  subnet_id      = aws_subnet.db_private_2.id
  route_table_id = aws_route_table.private_rt.id
}
