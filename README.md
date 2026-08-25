# ToggleMaster — Infra (Terraform)

Infraestrutura como código do ToggleMaster (Tech Challenge Fase 3 — Pós DevOps).
Provisiona a plataforma de 5 microsserviços tanto localmente (kind, pra testar
sem custo de AWS) quanto na AWS real (AWS Academy — LabRole).

## Estrutura

```
terraform/
  modules/
    networking/        VPC, subnets públicas/privadas, IGW, route tables
    eks/                Cluster EKS + Node Group (nodes em subnet pública, sem NAT)
    data-services/      3x RDS Postgres, ElastiCache Redis, DynamoDB, SQS
    ecr/                5 repositórios ECR (um por serviço)
    toggle-master-app/  Deploy dos 5 microsserviços no Kubernetes (genérico —
                         usado tanto pelo ambiente local quanto, futuramente,
                         poderia ser reusado pelo ambiente aws)
  environments/
    local/              kind + docker-compose.infra.yml — testa o design dos
                         módulos sem gastar créditos de AWS
    aws/                Ambiente real: networking + eks + data-services + ecr
docker-compose.infra.yml  Postgres x3 + Redis + LocalStack, usado só pelo
                           ambiente local (nodes do kind acessam via
                           host.docker.internal)
```

## Pré-requisitos

- Terraform >= 1.5
- AWS CLI configurado (`~/.aws/credentials` — no AWS Academy, as credenciais
  são temporárias e expiram em poucas horas, precisa renovar em
  Learner Lab → AWS Details → aba AWS CLI)
- Para o ambiente local: Docker, [kind](https://kind.sigs.k8s.io/), kubectl

## Ambiente AWS

Restrição do AWS Academy: o Terraform **não cria roles/policies de IAM** —
reusa a `LabRole` existente via `data "aws_iam_role"` (ver
`terraform/environments/aws/main.tf`).

Decisões de custo conscientes (ver comentários no código pra detalhes):
- Nodes do EKS ficam em subnets **públicas** — evita o custo do NAT Gateway
  enquanto o projeto é usado só pra estudo/demo.
- RDS/ElastiCache ficam em subnets **privadas** (só alcançáveis de dentro da VPC).
- `force_delete = true` nos repositórios ECR — como o ambiente é
  destruído/recriado com frequência (créditos do Academy), evita falha no
  `destroy` se algum repo tiver imagem.

### Bootstrap do backend remoto (S3) — uma vez só, fora do Terraform

```bash
aws s3api create-bucket --bucket SEU-BUCKET --region us-east-1
aws s3api put-bucket-versioning --bucket SEU-BUCKET --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket SEU-BUCKET --server-side-encryption-configuration file://sse.json
aws s3api put-public-access-block --bucket SEU-BUCKET --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

(`sse.json` = `{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}`
— grave num arquivo pra evitar problema de aspas no PowerShell.)

### Rodando

```bash
cd terraform/environments/aws
cp backend.hcl.example backend.hcl        # edite com o nome do seu bucket
cp terraform.tfvars.example terraform.tfvars  # edite com senhas reais

terraform init -backend-config backend.hcl
terraform plan
terraform apply
```

Outputs importantes: `configure_kubectl` (comando pronto pra apontar o
kubectl pro cluster), `ecr_repository_urls` (URLs pra usar no CI/CD),
endpoints dos bancos/Redis/SQS/DynamoDB.

### Destruindo (economizar créditos)

```bash
terraform destroy
```

O state fica no S3 — o bucket **não** é destruído por esse comando, então o
próximo `apply` reconecta no mesmo backend sem perder histórico.

## Ambiente local (kind)

Valida o design dos módulos sem tocar na AWS. Ver comentários em
`terraform/environments/local/main.tf` para o mapeamento completo de env vars.

```bash
docker compose -f docker-compose.infra.yml up -d
kind create cluster --name togglemaster-local

# build + load das 5 imagens (Dockerfiles vivem no repo dos serviços)
kind load docker-image auth-service:latest flag-service:latest \
  targeting-service:latest evaluation-service:latest analytics-service:latest \
  --name togglemaster-local

cd terraform/environments/local
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```
