# Знаходимо існуючий Internet Gateway у Default VPC
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Створюємо публічну таблицю маршрутизації 
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  tags = { Name = "public-rt-${var.env}" }
}

# Асоціюємо наші публічні підмережі (NAT та ALB) з публічною таблицею
resource "aws_route_table_association" "nat_assoc" {
  subnet_id      = aws_subnet.public_subnet_nat.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "alb_assoc_1" {
  subnet_id      = aws_subnet.custom_alb_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "alb_assoc_2" {
  subnet_id      = aws_subnet.custom_alb_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Створюємо постійний IP (Elastic IP) для NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Створюємо сам NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_nat.id

  tags = { Name = "nat-gateway-${var.env}" }
}