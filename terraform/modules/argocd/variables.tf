variable "namespace" {
  type    = string
  default = "argocd"
}

variable "gitops_repo_url" {
  description = "Repo Git (HTTPS) que contém a pasta de manifests que o ArgoCD sincroniza."
  type        = string
}

variable "gitops_path" {
  description = "Caminho, dentro do repo acima, com os manifests Kubernetes."
  type        = string
  default     = "gitops"
}

variable "gitops_target_revision" {
  description = "Branch/tag que o ArgoCD acompanha."
  type        = string
  default     = "master"
}

variable "app_namespace" {
  description = "Namespace onde a aplicação (ToggleMaster) é sincronizada."
  type        = string
  default     = "toggle-master"
}

variable "aws_region" {
  type = string
}

variable "cluster_name" {
  description = "Usado só pra gerar um kubeconfig temporário via `aws eks update-kubeconfig` na hora de aplicar a Application do ArgoCD."
  type        = string
}
