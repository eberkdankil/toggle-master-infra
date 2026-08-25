output "namespace" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "service_names" {
  description = "Nomes dos Services criados, úteis para kubectl port-forward."
  value       = { for name, svc in kubernetes_service.service : name => svc.metadata[0].name }
}
