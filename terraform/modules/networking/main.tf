locals {
  public_subnets  = { for idx, az in var.azs : az => var.public_subnet_cidrs[idx] }
  private_subnets = { for idx, az in var.azs : az => var.private_subnet_cidrs[idx] }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project}-public-${each.key}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "${var.project}-private-${each.key}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Subnets privadas ficam sem rota de saída pra internet por enquanto (sem NAT
# Gateway — decisão consciente pra não pagar por ele antes do EKS existir).
# A route table já existe e está associada, só falta a rota 0.0.0.0/0 quando o
# NAT for ligado (bloco comentado logo abaixo).
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------------
# NAT Gateway — desativado por decisão do time (custo ~US$0,045/h + dados
# mesmo sem tráfego). Descomentar quando o EKS for provisionado e as
# subnets privadas precisarem de saída pra internet (pull de imagens do
# ECR público, chamadas a APIs AWS, etc). Depois de descomentar, adicionar
# também o bloco `route` correspondente na aws_route_table.private acima.
# ------------------------------------------------------------------
# resource "aws_eip" "nat" {
#   domain = "vpc"
#
#   tags = {
#     Name = "${var.project}-nat-eip"
#   }
# }
#
# resource "aws_nat_gateway" "this" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = values(aws_subnet.public)[0].id
#   depends_on    = [aws_internet_gateway.this]
#
#   tags = {
#     Name = "${var.project}-nat"
#   }
# }
