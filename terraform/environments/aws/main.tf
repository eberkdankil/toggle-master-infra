# Ambiente AWS real (AWS Academy — LabRole, sem criação de IAM Roles/Policies
# neste código). Networking, EKS, bancos/mensageria e ECR — tudo ativo.

module "networking" {
  source = "../../modules/networking"

  project              = var.project
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# AWS Academy: reusa a LabRole existente (leitura, não cria nada) tanto pro
# cluster EKS quanto pro node group.
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Nodes em subnets PÚBLICAS de propósito — decisão consciente pra não pagar
# NAT Gateway. O Security Group do cluster (gerenciado pelo próprio EKS)
# ainda controla quem acessa o quê; não é "aberto pra internet" por causa
# disso, só os nodes têm IP público.
module "eks" {
  source = "../../modules/eks"

  cluster_name = var.cluster_name
  lab_role_arn = data.aws_iam_role.lab_role.arn
  subnet_ids   = values(module.networking.public_subnet_ids)
}

# Bancos de dados, cache, DynamoDB e SQS. RDS/ElastiCache ficam nas subnets
# PRIVADAS (só alcançáveis de dentro da VPC — os nodes do EKS, mesmo estando
# na pública, estão na mesma VPC e conseguem chegar lá via Security Group).
module "data_services" {
  source = "../../modules/data-services"

  project            = var.project
  vpc_id             = module.networking.vpc_id
  vpc_cidr           = module.networking.vpc_cidr
  private_subnet_ids = values(module.networking.private_subnet_ids)

  auth_db_password      = var.auth_db_password
  flags_db_password     = var.flags_db_password
  targeting_db_password = var.targeting_db_password
}

# 5 repositórios ECR, um por serviço — as URLs saem no output
# `ecr_repository_urls` pra usar no CI/CD (docker tag/push).
module "ecr" {
  source = "../../modules/ecr"
}

# ArgoCD + Application apontando pro repo de GitOps (repositório público,
# sem credencial necessária — confirmado via API do GitHub).
module "argocd" {
  source = "../../modules/argocd"

  gitops_repo_url = var.gitops_repo_url
  aws_region      = var.aws_region
  cluster_name    = module.eks.cluster_name
}
