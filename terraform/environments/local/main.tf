# Ambiente local: cluster kind já existente (criado fora do Terraform,
# ver README de "terraform/environments/local"), bancos/Redis/LocalStack
# rodando via docker-compose.infra.yml na máquina host.
#
# Pods dentro do kind alcançam o host via host.docker.internal — por isso
# todo endpoint "externo" abaixo aponta pra lá em vez de localhost.

locals {
  host_gateway = "host.docker.internal"

  config_map_data = {
    auth-service-port       = "8001"
    flag-service-port       = "8002"
    targeting-service-port  = "8003"
    evaluation-service-port = "8004"
    analytics-service-port  = "8005"

    auth-service-url      = "http://auth-service:8001"
    flag-service-url      = "http://flag-service:8002"
    targeting-service-url = "http://targeting-service:8003"

    redis-url = "redis://${local.host_gateway}:6379"

    aws-sqs-url        = "http://${local.host_gateway}:4566/000000000000/togglemaster-events"
    aws-dynamodb-table = "ToggleMasterAnalytics"
    aws-region         = "us-east-1"
    # Só o LocalStack precisa disso — nenhum serviço real na AWS lê essa chave,
    # o aws-sdk-go/boto3 ignoram AWS_ENDPOINT_URL vazio/ausente.
    aws-endpoint-url = "http://${local.host_gateway}:4566"
  }

  secret_data = {
    auth-db-url      = "postgres://auth_user:${var.auth_db_password}@${local.host_gateway}:5432/auth_db?sslmode=disable"
    flags-db-url     = "postgres://flags_user:${var.flags_db_password}@${local.host_gateway}:5433/flags_db"
    targeting-db-url = "postgres://targeting_user:${var.targeting_db_password}@${local.host_gateway}:5434/targeting_db"

    master-key      = var.master_key
    service-api-key = var.service_api_key

    # Credenciais dummy do LocalStack — não são segredos reais, mas ficam no
    # Secret (não em texto puro no Deployment) pra manter o mesmo padrão do
    # ambiente AWS, onde essas chaves sim são sensíveis de verdade.
    aws-access-key-id     = "test"
    aws-secret-access-key = "test"
  }
}

module "app" {
  source = "../../modules/toggle-master-app"

  config_map_data = local.config_map_data
  secret_data     = local.secret_data

  services = {
    auth-service = {
      image = "auth-service:latest"
      port  = 8001
      env_from_config = [
        { name = "PORT", key = "auth-service-port" },
      ]
      env_from_secret = [
        { name = "DATABASE_URL", key = "auth-db-url" },
        { name = "MASTER_KEY", key = "master-key" },
      ]
      resources = {
        requests = { cpu = "100m", memory = "64Mi" }
        limits   = { cpu = "500m", memory = "128Mi" }
      }
    }

    flag-service = {
      image = "flag-service:latest"
      port  = 8002
      env_from_config = [
        { name = "PORT", key = "flag-service-port" },
        { name = "AUTH_SERVICE_URL", key = "auth-service-url" },
      ]
      env_from_secret = [
        { name = "DATABASE_URL", key = "flags-db-url" },
      ]
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "256Mi" }
      }
    }

    targeting-service = {
      image = "targeting-service:latest"
      port  = 8003
      env_from_config = [
        { name = "PORT", key = "targeting-service-port" },
        { name = "AUTH_SERVICE_URL", key = "auth-service-url" },
      ]
      env_from_secret = [
        { name = "DATABASE_URL", key = "targeting-db-url" },
      ]
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "256Mi" }
      }
    }

    evaluation-service = {
      image = "evaluation-service:latest"
      port  = 8004
      env_from_config = [
        { name = "PORT", key = "evaluation-service-port" },
        { name = "REDIS_URL", key = "redis-url" },
        { name = "FLAG_SERVICE_URL", key = "flag-service-url" },
        { name = "TARGETING_SERVICE_URL", key = "targeting-service-url" },
        { name = "AWS_SQS_URL", key = "aws-sqs-url" },
        { name = "AWS_REGION", key = "aws-region" },
        { name = "AWS_ENDPOINT_URL", key = "aws-endpoint-url" },
      ]
      env_from_secret = [
        { name = "SERVICE_API_KEY", key = "service-api-key" },
        { name = "AWS_ACCESS_KEY_ID", key = "aws-access-key-id" },
        { name = "AWS_SECRET_ACCESS_KEY", key = "aws-secret-access-key" },
      ]
      resources = {
        requests = { cpu = "200m", memory = "64Mi" }
        limits   = { cpu = "1000m", memory = "256Mi" }
      }
    }

    analytics-service = {
      image = "analytics-service:latest"
      port  = 8005
      env_from_config = [
        { name = "PORT", key = "analytics-service-port" },
        { name = "AWS_SQS_URL", key = "aws-sqs-url" },
        { name = "AWS_DYNAMODB_TABLE", key = "aws-dynamodb-table" },
        { name = "AWS_REGION", key = "aws-region" },
        { name = "AWS_ENDPOINT_URL", key = "aws-endpoint-url" },
      ]
      env_from_secret = [
        { name = "AWS_ACCESS_KEY_ID", key = "aws-access-key-id" },
        { name = "AWS_SECRET_ACCESS_KEY", key = "aws-secret-access-key" },
      ]
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "256Mi" }
      }
      # Fiel ao k8s/08-analytics-service.yaml original: sem probes.
      create_probes = false
    }
  }
}

output "namespace" {
  value = module.app.namespace
}

output "service_names" {
  value = module.app.service_names
}
