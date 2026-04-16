# Get the current region (e.g., us-east-1)
data "aws_region" "current" {}

# Create a Private Route Table for your subnets
resource "aws_route_table" "private_rt" {
  vpc_id = data.aws_vpc.default.id
  tags   = { Name = "private-rt-${var.env}" }
}

# Create the free S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # This attaches the tunnel directly to your private route table
  route_table_ids = [aws_route_table.private_rt.id]
}

# Associate your private subnets with this route table
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.custom_asg_subnet.id
  route_table_id = aws_route_table.private_rt.id
}





# The EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "private_connect" {
  # Place the endpoint in the same private subnet as your EC2 instance
  subnet_id = aws_subnet.custom_asg_subnet.id

  # Attach the dedicated endpoint security group created above
  security_group_ids = [aws_security_group.eice_sg.id]

  # CRITICAL: Set to false so the private EC2 instance can successfully 
  # route the reply traffic back to the endpoint's internal IP.
  preserve_client_ip = false

  tags = {
    Name = "private-eice-endpoint"
  }
}



# Список необхідних сервісів для роботи SSM без інтернету
locals {
  ssm_services = ["ssm", "ssmmessages", "ec2messages"]
}

resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each            = toset(local.ssm_services)
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  
  subnet_ids          = [aws_subnet.custom_asg_subnet.id]
  security_group_ids  = [aws_security_group.ssm_endpoints_sg.id] 
  private_dns_enabled = true
}