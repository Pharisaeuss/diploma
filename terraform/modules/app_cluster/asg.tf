resource "aws_launch_template" "app_lt" {
  name_prefix            = "app-template-${var.env}"
  image_id               = local.ami_id
  instance_type          = var.machine_type
  vpc_security_group_ids = [var.asg_sg_id]

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  tags = {
    Name = "app-launch-template-${var.env}"
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name             = "app-asg-${var.env}"
  desired_capacity = 3
  max_size         = 5
  min_size         = 2

  vpc_zone_identifier = var.asg_subnet_ids

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = aws_launch_template.app_lt.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "asg-${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

resource "aws_ssm_parameter" "env" {
  name  = "/${var.env}/app/env"
  type  = "String"
  value = var.env
}

resource "aws_ssm_parameter" "region" {
  name  = "/${var.env}/app/region"
  type  = "String"
  value = var.region
}