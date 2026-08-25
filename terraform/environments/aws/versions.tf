terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
