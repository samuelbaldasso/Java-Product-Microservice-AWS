environment = "dev"
aws_region  = "us-east-1"

# Project
project_name = "my-java-backend"

# Database
db_username = "admin"
db_password = "Darude97"
db_name     = "myappdb"

# SSL Certificate
ssl_certificate_arn = ""

# Network
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
enable_nat_gateway = false

# ECS Configuration
ecs_instance_type    = "t3.small"
ecs_desired_capacity = 1
ecs_min_capacity     = 1
ecs_max_capacity     = 3

# Service
service_desired_count = 1
service_min_count     = 1
service_max_count     = 5

# Tasks
task_cpu    = "512"
task_memory = "1024"
