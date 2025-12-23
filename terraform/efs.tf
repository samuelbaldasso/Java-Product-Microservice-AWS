# EFS File System for RabbitMQ
resource "aws_efs_file_system" "rabbitmq" {
  creation_token = "${var.project_name}-rabbitmq-efs-${var.environment}"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.project_name}-rabbitmq-efs-${var.environment}"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "rabbitmq" {
  count           = length(var.availability_zones)
  file_system_id  = aws_efs_file_system.rabbitmq.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

# EFS Access Point
resource "aws_efs_access_point" "rabbitmq" {
  file_system_id = aws_efs_file_system.rabbitmq.id

  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/rabbitmq"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "755"
    }
  }

  tags = {
    Name = "${var.project_name}-rabbitmq-access-point-${var.environment}"
  }
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  name_prefix = "${var.project_name}-efs-sg-"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NFS from ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-efs-sg-${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}