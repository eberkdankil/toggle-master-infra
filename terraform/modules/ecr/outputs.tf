output "repository_urls" {
  description = "Nome do repositório -> URL completa (usar no docker tag/push e no CI/CD)."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "registry_id" {
  value = length(aws_ecr_repository.this) > 0 ? values(aws_ecr_repository.this)[0].registry_id : null
}
