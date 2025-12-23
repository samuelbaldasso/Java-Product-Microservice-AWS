#!/bin/bash
set -ex

# Update system
yum update -y

# Configure ECS agent
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true >> /etc/ecs/ecs.config

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Install SSM agent (for debugging)
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Configure Docker log rotation
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

# Start ECS agent
systemctl enable ecs
systemctl start ecs