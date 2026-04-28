# Application Load Balancer
resource "aws_lb" "main_alb" {
  name               = "app-alb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [aws_subnet.custom_alb_subnet_1.id, aws_subnet.custom_alb_subnet_2.id]

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "alb-logs/${var.env}"
    enabled = true
  }

  tags = { Name = "main-alb-${var.env}" }
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group-${var.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Connect ASG to the Target Group
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.id
  lb_target_group_arn    = aws_lb_target_group.app_tg.arn
}