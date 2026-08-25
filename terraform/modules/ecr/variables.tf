variable "repository_names" {
  description = "Nomes dos repositórios ECR a criar, um por serviço."
  type        = list(string)
  default = [
    "toggle-master/auth-service",
    "toggle-master/flag-service",
    "toggle-master/targeting-service",
    "toggle-master/evaluation-service",
    "toggle-master/analytics-service",
  ]
}

variable "image_tag_mutability" {
  description = "MUTABLE mantém compatibilidade com o ecr-push.sh atual (tag latest reaproveitada). Trocar pra IMMUTABLE quando o CI/CD passar a taguear por commit hash."
  type        = string
  default     = "MUTABLE"
}
