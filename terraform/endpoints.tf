# Create a Private Route Table for your subnets
resource "aws_route_table" "private_rt" {
  vpc_id = data.aws_vpc.default.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id 
  }

  tags = { Name = "private-rt-${var.env}" }
}

# Associate your private subnets with this route table
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.custom_asg_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Асоціації підмереж бази даних (RDS) з приватною таблицею
resource "aws_route_table_association" "db_assoc_1" {
  subnet_id      = aws_subnet.db_private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "db_assoc_2" {
  subnet_id      = aws_subnet.db_private_2.id
  route_table_id = aws_route_table.private_rt.id
}


# Create the free S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private_rt.id]
}

# The EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "private_connect" {
  subnet_id = aws_subnet.custom_asg_subnet.id
  security_group_ids = [aws_security_group.eice_sg.id]
  preserve_client_ip = false

  tags = {
    Name = "private-eice-endpoint"
  }
}