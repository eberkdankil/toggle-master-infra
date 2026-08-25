variable "namespace" {
  description = "Namespace onde os recursos do ToggleMaster serão criados."
  type        = string
  default     = "toggle-master"
}

variable "config_map_data" {
  description = "Dados não sensíveis (URLs, nomes de fila/tabela, portas) expostos via ConfigMap toggle-master-config."
  type        = map(string)
}

variable "secret_data" {
  description = "Dados sensíveis (connection strings, senhas, chaves de API, credenciais AWS) expostos via Secret toggle-master-secret."
  type        = map(string)
  sensitive   = true
}

variable "services" {
  description = <<-EOT
    Um serviço por chave (auth-service, flag-service, targeting-service,
    evaluation-service, analytics-service). Cada entrada descreve o
    Deployment+Service correspondente. As variáveis de ambiente do
    container são sempre referências (configMapKeyRef/secretKeyRef) às
    chaves de `config_map_data`/`secret_data` — nenhum valor literal
    sensível passa pela spec do Deployment.
  EOT
  type = map(object({
    image = string
    port  = number

    env_from_config = optional(list(object({
      name = string
      key  = string
    })), [])

    env_from_secret = optional(list(object({
      name = string
      key  = string
    })), [])

    resources = object({
      requests = object({ cpu = string, memory = string })
      limits   = object({ cpu = string, memory = string })
    })

    health_path    = optional(string, "/health")
    create_probes  = optional(bool, true)
    create_service = optional(bool, true)
    replicas       = optional(number, 1)
  }))
}
