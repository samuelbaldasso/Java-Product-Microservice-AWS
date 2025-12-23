# Product Service – AWS Integration Study Case

Microservice built with **Java and Spring Boot** as a **study case** to demonstrate **integration with AWS managed services**, while keeping the **runtime local** for simplicity.

> ⚠️ This project **does not represent a complete corporate deployment** or a real production environment.

---

## 📌 Project Scope

This study aims to:

- Demonstrate Spring Boot microservice integration with AWS services
- Use a managed database (Amazon RDS)
- Send metrics and logs to Amazon CloudWatch
- Publish container images to Amazon ECR
- Consume messaging via RabbitMQ (local)
- Keep the environment simple, controlled, and low-cost

📍 **The microservice runs locally (Docker/Podman)** 

AWS is used only as **supporting infrastructure**.

---

## 🏗️ Architecture (Study)

```
Local Machine (Podman)
├─ product-service (Spring Boot)
├─ inventory-service (Spring Boot)
├─ RabbitMQ (local)
│
└── AWS
    ├─ RDS (PostgreSQL)
    ├─ CloudWatch (logs & metrics)
    ├─ ECR (container registry)
    └─ CloudFront (edge / HTTP proxy)
```

---

## 📦 Technologies Used

### Backend
- Java 17
- Spring Boot
- Spring Data JPA
- Spring Security (basic configuration)
- Flyway
- Micrometer

### AWS Infrastructure (integration)
- Amazon RDS (PostgreSQL)
- Amazon CloudWatch (logs & metrics)
- Amazon ECR (container images)
- Amazon CloudFront (proxy / edge)

### Messaging
- RabbitMQ (local)

### Containers
- Podman
- Optimized Dockerfile (multi-stage)

---

## 🔧 Execution Profiles

- `local` → complete local development
- `aws` → integration with AWS services (RDS, CloudWatch, etc.)

Example:

```bash
SPRING_PROFILES_ACTIVE=aws
```

---

## 🚀 How to Run Locally

### Prerequisites

- Java 17
- Maven
- Podman or Docker
- RabbitMQ running locally
- AWS CLI configured (for RDS and CloudWatch access)

### Build

```bash
./mvnw clean package
```

### Run

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=aws
```

---

## 📊 Observability

- Logs automatically sent to CloudWatch
- Custom metrics via Micrometer
- Health checks via Spring Actuator

---

## 🗄️ Database

- PostgreSQL hosted on Amazon RDS
- Migrations managed via Flyway
- Direct connection from local runtime

---

## 📨 Messaging

- Asynchronous communication with other services via RabbitMQ
- RabbitMQ running locally to simplify the study
- Focus on decoupling between microservices

---

## 🔐 Security (Study Scope)

- External credentials (not hardcoded)
- Use of environment profiles
- No focus on advanced IAM or OAuth2 (out of scope)

---

## 🚧 Possible Evolutions (Currently Out of Scope)

- Deploy services on AWS ECS
- Introduction of Application Load Balancer
- Automated CI/CD
- Auto Scaling
- AWS Secrets Manager
- Separated environments (dev/staging/prod)

These points are acknowledged but intentionally not implemented in this study.

---

## 📄 License

MIT
