# Usar imagem que suporta ARM64 nativamente
FROM docker.io/amazoncorretto:17-alpine AS build

WORKDIR /app

# Instalar dependências necessárias
RUN apk add --no-cache curl

# Criar usuário não-root
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser && \
    chown -R appuser:appgroup /app

# Copiar Maven wrapper e pom.xml
COPY --chown=appuser:appgroup .mvn .mvn
COPY --chown=appuser:appgroup mvnw .
COPY --chown=appuser:appgroup pom.xml .

USER appuser

# Download dependencies (cache layer)
RUN ./mvnw dependency:go-offline -B || true

# Copiar código fonte
COPY --chown=appuser:appgroup src ./src

# Build da aplicação
RUN ./mvnw clean package -DskipTests -B

# Runtime stage - usar imagem menor
FROM docker.io/amazoncorretto:17-alpine

# Instalar curl para health checks
RUN apk add --no-cache curl

# Criar usuário não-root
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

WORKDIR /app

# Variáveis de ambiente
ENV AWS_REGION=us-east-1 \
    JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Copiar JAR
COPY --from=build --chown=appuser:appgroup /app/target/*.jar app.jar

USER appuser

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]