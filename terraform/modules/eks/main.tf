# AWS Academy: nada de aws_iam_role/aws_iam_policy aqui — o cluster e o node
# group reusam a LabRole (var.lab_role_arn), resolvida via data source no
# ambiente chamador (terraform/environments/aws/main.tf).

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.lab_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = false
  }
}

# Sem isso, o node group usa o launch template default do EKS, que em
# alguns casos deixa o hop limit do IMDS em 1 — suficiente pra instância
# EC2 buscar a própria role, mas não pro processo dentro de um container
# (adiciona um hop de rede extra). Resultado: boto3 dá "Unable to locate
# credentials" mesmo a LabRole estando correta no node group inteiro.
resource "aws_launch_template" "node" {
  name_prefix = "${var.cluster_name}-ng-"

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = var.lab_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.instance_types

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  # Evita que o Terraform tente recriar o node group por causa de scaling
  # feito pelo HPA/cluster autoscaler fora do Terraform.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_eks_cluster.this]
}
