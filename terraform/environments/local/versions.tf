terraform {
  required_version = ">= 1.5"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }

  # Backend local (arquivo terraform.tfstate neste diretório) — intencional
  # para esta fase de teste local. O ambiente AWS real (terraform/environments/aws,
  # a ser criado depois) usará backend "s3" conforme exigido pelo Tech Challenge.
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}
