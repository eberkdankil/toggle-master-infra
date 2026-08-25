resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  # Ambiente efêmero, recriado/destruído com frequência (créditos do Academy)
  # — sem isso, terraform destroy falha se o repo já tiver alguma imagem.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
