output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_address" {
  description = "RDS address"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "rabbitmq_endpoint" {
  description = "RabbitMQ endpoint"
  value       = aws_lb.rabbitmq.dns_name
}

output "rabbitmq_management_url" {
  description = "RabbitMQ Management URL"
  value       = "http://${aws_lb.rabbitmq.dns_name}:15672"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.app_distribution.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.app_distribution.domain_name
}