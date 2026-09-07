variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "togglemaster"
}

variable "cluster_name" {
  description = "Nome que o cluster EKS terá quando for criado (ainda não nesta fase — só usado nas tags das subnets)."
  type        = string
  default     = "togglemaster"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "auth_db_password" {
  type      = string
  sensitive = true
}

variable "flags_db_password" {
  type      = string
  sensitive = true
}

variable "targeting_db_password" {
  type      = string
  sensitive = true
}

variable "gitops_repo_url" {
  description = "Repo (público) com a pasta gitops/ que o ArgoCD sincroniza."
  type        = string
  default     = "https://github.com/eberkdankil/toggle-master-tc2-fiap.git"
}
