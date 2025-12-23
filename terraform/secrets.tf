# Database Credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${var.project_name}-db-credentials-"
  description             = "Database credentials for ${var.project_name}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = {
    Name = "${var.project_name}-db-credentials-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}

# RabbitMQ Credentials
resource "aws_secretsmanager_secret" "rabbitmq_credentials" {
  name_prefix             = "${var.project_name}-rabbitmq-credentials-"
  description             = "RabbitMQ credentials for ${var.project_name}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = {
    Name = "${var.project_name}-rabbitmq-credentials-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "rabbitmq_credentials" {
  secret_id = aws_secretsmanager_secret.rabbitmq_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.rabbitmq.result
    host     = aws_lb.rabbitmq.dns_name
    port     = 5672
  })
}

# Generate random password for RabbitMQ
resource "random_password" "rabbitmq" {
  length  = 32
  special = true
}