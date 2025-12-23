variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "my-java-backend"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

# Database variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "myapp"
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# ECS variables
variable "ecs_instance_type" {
  description = "ECS EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ecs_desired_capacity" {
  description = "Desired number of ECS EC2 instances"
  type        = number
  default     = 2
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS EC2 instances"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS EC2 instances"
  type        = number
  default     = 4
}

# Task variables
variable "task_cpu" {
  description = "Task CPU units"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Task memory in MB"
  type        = string
  default     = "1024"
}

variable "service_desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "service_min_count" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "service_max_count" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

# SSL Certificate
variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
}