resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]
}

resource "aws_ec2_instance_connect_endpoint" "private_connect" {
  subnet_id          = aws_subnet.custom_asg_subnet.id
  security_group_ids = [aws_security_group.eice_sg.id]
  preserve_client_ip = false
  tags = { Name = "private-eice-endpoint-${var.env}" }
}