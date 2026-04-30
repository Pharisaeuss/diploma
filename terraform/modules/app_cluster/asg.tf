resource "aws_launch_template" "app_lt" {
  name_prefix            = "app-template-${var.env}"
  image_id               = local.ami_id
  instance_type          = var.machine_type
  vpc_security_group_ids = [var.asg_sg_id]

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  user_data = base64encode(<<EOF
#!/bin/bash
mkdir -p /etc/systemd/system/streamlit.service.d

cat <<EOT > /etc/systemd/system/streamlit.service.d/env.conf
[Service]
Environment="ENV=${var.env}"
Environment="AWS_DEFAULT_REGION=${var.region}"
EOT

systemctl daemon-reload
systemctl restart streamlit
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
  name             = "app-asg-${var.env}"
  desired_capacity = 2
  max_size         = 4
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
    # Triggers after new AMI is available
    #triggers = ["tag"]
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