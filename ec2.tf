resource "aws_launch_template" "app_lt" {
  name_prefix            = "my-app-template-${var.env}"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.machine_type
  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  # Attach the IAM Role here
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_s3_profile.name
  }

  user_data = base64encode(<<-EOF
                #!/bin/bash
                yum update -y
                yum install httpd -y
                service httpd start
                chkconfig httpd on
                echo "<html><h1>Hello World</h1></html>" > /var/www/html/index.html
              EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "asg-instance-${var.env}"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name             = "my-asg-${var.env}"
  desired_capacity = 1
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier = [aws_subnet.custom_asg_subnet.id]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
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
    target_value = 50.0 # Target 50% CPU utilization
  }
}