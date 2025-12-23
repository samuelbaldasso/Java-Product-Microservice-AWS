# Launch Template for ECS EC2 instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-ecs-lt-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.ecs_instance_type

  vpc_security_group_ids = [aws_security_group.ecs_tasks.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = aws_ecs_cluster.main.name
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-ecs-instance-${var.environment}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs" {
  name_prefix         = "${var.project_name}-ecs-asg-"
  vpc_zone_identifier = aws_subnet.private[*].id
  desired_capacity    = var.ecs_desired_capacity
  min_size            = var.ecs_min_capacity
  max_size            = var.ecs_max_capacity

  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# Get latest ECS-optimized AMI
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}