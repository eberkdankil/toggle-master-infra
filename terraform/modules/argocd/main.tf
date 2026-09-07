# Instala o ArgoCD via chart oficial (argo-helm) e cria a Application que
# aponta pro repositório de GitOps — depois disso, todo o resto do
# ToggleMaster (Deployments/Services/ConfigMap/HPA) é sincronizado pelo
# próprio ArgoCD, não pelo Terraform.
#
# `version` do chart fica sem pin de propósito: preferimos pegar a versão
# atual do repositório do Helm a arriscar fixar algo que pode não existir
# mais quando isso for aplicado.
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = true
}

# Terraform providers "k8s nativos" (kubernetes/kubectl) configurados com
# valores de um cluster criado na mesma apply têm um histórico de bugs de
# timing na hora de "Configure()" (o kubernetes_manifest da hashicorp já deu
# erro de REST client; o kubectl da alekc também). Pra não ficar refém disso,
# aplicamos a Application via `kubectl` de verdade, chamado depois que o
# helm_release do ArgoCD (e portanto o cluster) já existem de fato.
resource "local_file" "toggle_master_app" {
  filename = "${path.module}/.generated-toggle-master-app.yaml"
  content = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "toggle-master"
      namespace = var.namespace
    }
    spec = {
      project = "default"

      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_target_revision
        path           = var.gitops_path
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.app_namespace
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })
}

resource "null_resource" "apply_toggle_master_app" {
  depends_on = [helm_release.argocd, local_file.toggle_master_app]

  triggers = {
    manifest_sha = local_file.toggle_master_app.content_sha256
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name} --kubeconfig ${path.module}/.kubeconfig-argocd && kubectl --kubeconfig ${path.module}/.kubeconfig-argocd apply -f ${local_file.toggle_master_app.filename}"
  }
}
