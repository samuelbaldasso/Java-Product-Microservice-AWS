environment = "production"
aws_region  = "us-east-1"

# VPC
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
enable_nat_gateway = true

# Database
db_instance_class       = "db.t3.small"
db_allocated_storage    = 50
db_max_allocated_storage = 200

# ECS
ecs_instance_type    = "t3.medium"
ecs_desired_capacity = 3
ecs_min_capacity     = 2
ecs_max_capacity     = 10

# Service
service_desired_count = 3
service_min_count     = 2
service_max_count     = 20

# Tasks
task_cpu    = "1024"
task_memory = "2048"