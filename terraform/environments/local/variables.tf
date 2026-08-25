variable "kubeconfig_path" {
  description = "Caminho do kubeconfig local."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Contexto do kubeconfig apontando para o cluster kind já criado (kind create cluster --name togglemaster-local)."
  type        = string
  default     = "kind-togglemaster-local"
}

variable "master_key" {
  description = "MASTER_KEY do auth-service, usada para criar API keys via /admin/keys."
  type        = string
  sensitive   = true
}

variable "service_api_key" {
  description = <<-EOT
    API key interna usada pelo evaluation-service para chamar
    flag-service/targeting-service. O default abaixo já vem semeado
    (via hash SHA-256) no init.sql do postgres-auth para ambiente local
    — não precisa criar via POST /admin/keys nem recriar a cada subida
    do ambiente. Só troque se também atualizar o hash correspondente em
    auth-service/db/init.sql.
  EOT
  type        = string
  sensitive   = true
  default     = "tm_key_e5873e855f9948ea109faecc22ca0f4f0dd0885e80c51e8f5d46e1b14e645bfb"
}

variable "auth_db_password" {
  type      = string
  sensitive = true
  default   = "auth_pass"
}

variable "flags_db_password" {
  type      = string
  sensitive = true
  default   = "flags_pass"
}

variable "targeting_db_password" {
  type      = string
  sensitive = true
  default   = "targeting_pass"
}
