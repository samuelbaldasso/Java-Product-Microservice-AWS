# RabbitMQ ECS Task Definition
resource "aws_ecs_task_definition" "rabbitmq" {
  family                   = "${var.project_name}-rabbitmq-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "rabbitmq"
      image     = "rabbitmq:3.12-management-alpine"
      essential = true

      portMappings = [
        {
          containerPort = 5672
          protocol      = "tcp"
        },
        {
          containerPort = 15672
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "RABBITMQ_DEFAULT_USER"
          value = "admin"
        }
      ]

      secrets = [
        {
          name      = "RABBITMQ_DEFAULT_PASS"
          valueFrom = aws_secretsmanager_secret.rabbitmq_credentials.arn
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "rabbitmq-data"
          containerPath = "/var/lib/rabbitmq"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.rabbitmq.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "rabbitmq"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "rabbitmq-diagnostics -q ping"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "rabbitmq-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.rabbitmq.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.rabbitmq.id
      }
    }
  }

  tags = {
    Name = "${var.project_name}-rabbitmq-task-${var.environment}"
  }
}

# RabbitMQ ECS Service
resource "aws_ecs_service" "rabbitmq" {
  name            = "${var.project_name}-rabbitmq-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.rabbitmq.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.rabbitmq.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rabbitmq_amqp.arn
    container_name   = "rabbitmq"
    container_port   = 5672
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rabbitmq_mgmt.arn
    container_name   = "rabbitmq"
    container_port   = 15672
  }

  depends_on = [
    aws_efs_mount_target.rabbitmq,
    aws_lb_listener.rabbitmq_amqp
  ]

  tags = {
    Name = "${var.project_name}-rabbitmq-service-${var.environment}"
  }
}

# CloudWatch Log Group for RabbitMQ
resource "aws_cloudwatch_log_group" "rabbitmq" {
  name              = "/ecs/${var.project_name}-rabbitmq-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-rabbitmq-logs-${var.environment}"
  }
}

# Internal NLB for RabbitMQ
resource "aws_lb" "rabbitmq" {
  name               = "${var.project_name}-rabbitmq-nlb-${var.environment}"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.private[*].id

  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-rabbitmq-nlb-${var.environment}"
  }
}

# Target Group for AMQP
resource "aws_lb_target_group" "rabbitmq_amqp" {
  name_prefix = "rmq-"
  port        = 5672
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled  = true
    protocol = "TCP"
    port     = 5672
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-rabbitmq-amqp-tg-${var.environment}"
  }
}

# Target Group for Management
resource "aws_lb_target_group" "rabbitmq_mgmt" {
  name_prefix = "rmqm-"
  port        = 15672
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled  = true
    protocol = "HTTP"
    path     = "/api/health/checks/alarms"
    port     = 15672
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-rabbitmq-mgmt-tg-${var.environment}"
  }
}

# NLB Listeners
resource "aws_lb_listener" "rabbitmq_amqp" {
  load_balancer_arn = aws_lb.rabbitmq.arn
  port              = 5672
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbitmq_amqp.arn
  }
}

resource "aws_lb_listener" "rabbitmq_mgmt" {
  load_balancer_arn = aws_lb.rabbitmq.arn
  port              = 15672
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbitmq_mgmt.arn
  }
}