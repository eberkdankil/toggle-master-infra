terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # Backend parcial de propósito: bucket/region/key não ficam hardcoded aqui
  # porque são específicos de cada conta/execução (nome de bucket S3 é
  # globalmente único). Valores reais vêm de backend.hcl (gitignored, veja
  # backend.hcl.example) via:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

# kubernetes/helm autenticam no cluster que o módulo eks acabou de criar —
# nada de kubeconfig local aqui, o token vem direto da API da AWS
# (aws_eks_cluster_auth), então funciona mesmo antes de você rodar
# `aws eks update-kubeconfig`.
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
