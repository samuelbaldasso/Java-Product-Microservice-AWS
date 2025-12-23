aws_region  = "us-east-1"
environment = "dev"

# Database
db_username = "admin"
db_password = "Darude97"
db_name     = "myapp"

# ECS Configuration
ecs_instance_type      = "t3.medium"
ecs_desired_capacity   = 2
ecs_min_capacity       = 1
ecs_max_capacity       = 4

service_desired_count = 2
service_min_count     = 1
service_max_count     = 10

# Costs optimization for dev
# ecs_instance_type = "t3.small"
# ecs_desired_capacity = 1
# db_instance_class = "db.t3.micro"