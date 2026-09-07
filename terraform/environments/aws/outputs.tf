output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "lab_role_arn" {
  value = data.aws_iam_role.lab_role.arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_node_group_status" {
  value = module.eks.node_group_status
}

output "configure_kubectl" {
  description = "Rode este comando pra apontar o kubectl pro cluster recém-criado."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "auth_db_endpoint" {
  value = module.data_services.auth_db_endpoint
}

output "flags_db_endpoint" {
  value = module.data_services.flags_db_endpoint
}

output "targeting_db_endpoint" {
  value = module.data_services.targeting_db_endpoint
}

output "redis_endpoint" {
  value = module.data_services.redis_endpoint
}

output "dynamodb_table_name" {
  value = module.data_services.dynamodb_table_name
}

output "sqs_queue_url" {
  value = module.data_services.sqs_queue_url
}

output "ecr_repository_urls" {
  description = "Nome do repositório -> URL completa. Usar essas URLs no docker tag/push e nos secrets/vars do CI/CD."
  value       = module.ecr.repository_urls
}

output "argocd_get_admin_password" {
  description = "Rode este comando (depois do kubectl apontar pro cluster) pra pegar a senha inicial do usuário admin do ArgoCD."
  value       = "kubectl -n ${module.argocd.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_port_forward" {
  description = "Acesso à UI do ArgoCD (sem Ingress configurado ainda)."
  value       = "kubectl -n ${module.argocd.namespace} port-forward svc/argocd-server 8080:443"
}
