.PHONY: help build test deploy-infra deploy-app destroy logs

include .env
export

ENVIRONMENT ?= production

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Local Development
build: ## Build locally with Podman
	@./scripts/build-local-podman.sh

test: ## Run tests
	@./mvnw test

# Infrastructure
terraform-init: ## Initialize Terraform
	@./scripts/terraform-init.sh $(ENVIRONMENT)

terraform-plan: ## Plan Terraform changes
	@./scripts/terraform-deploy.sh $(ENVIRONMENT) plan

terraform-apply: terraform-init ## Apply Terraform changes
	@./scripts/terraform-deploy.sh $(ENVIRONMENT) apply

terraform-destroy: ## Destroy infrastructure
	@cd terraform && terraform destroy -var="environment=$(ENVIRONMENT)" -var-file="environments/$(ENVIRONMENT).tfvars"

# Application Deployment
deploy-app: ## Deploy application to ECS
	@./scripts/deploy-to-aws.sh $(ENVIRONMENT)

deploy-full: terraform-apply deploy-app ## Full deployment (infra + app)

# Monitoring & Logs
logs: ## Tail ECS logs
	@aws logs tail /ecs/my-java-backend-$(ENVIRONMENT) --follow --region $(AWS_REGION)

service-status: ## Check ECS service status
	@aws ecs describe-services \
		--cluster my-java-backend-cluster-$(ENVIRONMENT) \
		--services my-java-backend-service-$(ENVIRONMENT) \
		--region $(AWS_REGION) \
		--query 'services[0].[status,runningCount,desiredCount]' \
		--output table

tasks: ## List running tasks
	@aws ecs list-tasks \
		--cluster my-java-backend-cluster-$(ENVIRONMENT) \
		--service-name my-java-backend-service-$(ENVIRONMENT) \
		--region $(AWS_REGION) \
		--output table

# Database
db-connect: ## Connect to RDS
	@DB_HOST=$$(terraform output -raw db_address 2>/dev/null || echo "localhost") && \
	psql -h $$DB_HOST -U $(DB_USER) -d $(DB_NAME)

db-migrate: ## Run database migrations
	@./mvnw flyway:migrate -Dspring-boot.run.profiles=aws

# RabbitMQ
rabbitmq-ui: ## Open RabbitMQ Management UI
	@RABBITMQ_URL=$$(aws elbv2 describe-load-balancers \
		--region $(AWS_REGION) \
		--query "LoadBalancers[?contains(LoadBalancerName, 'rabbitmq-nlb')].DNSName" \
		--output text) && \
	echo "RabbitMQ Management: http://$$RABBITMQ_URL:15672" && \
	open "http://$$RABBITMQ_URL:15672" || xdg-open "http://$$RABBITMQ_URL:15672"

# Utilities
ssh-ecs: ## SSH into ECS instance
	@INSTANCE_ID=$$(aws ec2 describe-instances \
		--filters "Name=tag:Name,Values=my-java-backend-ecs-instance-$(ENVIRONMENT)" \
		"Name=instance-state-name,Values=running" \
		--query 'Reservations[0].Instances[0].InstanceId' \
		--output text) && \
	aws ssm start-session --target $$INSTANCE_ID

exec-task: ## Execute command in running task
	@TASK_ARN=$$(aws ecs list-tasks \
		--cluster my-java-backend-cluster-$(ENVIRONMENT) \
		--service-name my-java-backend-service-$(ENVIRONMENT) \
		--region $(AWS_REGION) \
		--query 'taskArns[0]' \
		--output text) && \
	aws ecs execute-command \
		--cluster my-java-backend-cluster-$(ENVIRONMENT) \
		--task $$TASK_ARN \
		--container app \
		--interactive \
		--command "/bin/sh"

scale-up: ## Scale up service
	@aws ecs update-service \
		--cluster my-java-backend-cluster-$(ENVIRONMENT) \
		--service my-java-backend-service-$(ENVIRONMENT) \
		--desired-count 5 \
		--region $(AWS_REGION)

scale-down: ## Scale down service
	@aws ecs update-service \
		--cluster my-java-backend-cluster-$(ENVIRONMENT) \
		--service my-java-backend-service-$(ENVIRONMENT) \
		--desired-count 1 \
		--region $(AWS_REGION)

# Health Checks
health-check: ## Check application health
	@ALB_DNS=$$(aws elbv2 describe-load-balancers \
		--region $(AWS_REGION) \
		--query "LoadBalancers[?contains(LoadBalancerName, 'my-java-backend-alb')].DNSName" \
		--output text) && \
	curl -sf "http://$$ALB_DNS/health" | jq . || echo "Health check failed"

cloudfront-invalidate: ## Invalidate CloudFront cache
	@aws cloudfront create-invalidation \
		--distribution-id $(CLOUDFRONT_DISTRIBUTION_ID) \
		--paths "/*" \
		--region $(AWS_REGION)

# Cost Management
cost-estimate: ## Estimate monthly costs
	@echo "Estimating costs for $(ENVIRONMENT)..."
	@aws ce get-cost-and-usage \
		--time-period Start=2024-01-01,End=2024-01-31 \
		--granularity MONTHLY \
		--metrics BlendedCost \
		--filter file://cost-filter.json

# Cleanup
clean-ecr: ## Clean old ECR images
	@./scripts/clean-ecr.sh $(ENVIRONMENT)

clean-logs: ## Delete old CloudWatch logs
	@aws logs delete-log-group --log-group-name /ecs/my-java-backend-$(ENVIRONMENT) || true

# Documentation
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@./mvnw javadoc:javadoc
	@echo "✅ Documentation generated in target/site/apidocs/"