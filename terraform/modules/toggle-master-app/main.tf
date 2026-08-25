resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_config_map" "this" {
  metadata {
    name      = "toggle-master-config"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  data = var.config_map_data
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "toggle-master-secret"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = var.secret_data
}

resource "kubernetes_deployment" "service" {
  for_each = var.services

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = { app = each.key }
  }

  spec {
    replicas = each.value.replicas

    selector {
      match_labels = { app = each.key }
    }

    template {
      metadata {
        labels = { app = each.key }
      }

      spec {
        container {
          name              = each.key
          image             = each.value.image
          image_pull_policy = "Never"

          port {
            container_port = each.value.port
          }

          dynamic "env" {
            for_each = each.value.env_from_config
            content {
              name = env.value.name
              value_from {
                config_map_key_ref {
                  name = kubernetes_config_map.this.metadata[0].name
                  key  = env.value.key
                }
              }
            }
          }

          dynamic "env" {
            for_each = each.value.env_from_secret
            content {
              name = env.value.name
              value_from {
                secret_key_ref {
                  name = kubernetes_secret.this.metadata[0].name
                  key  = env.value.key
                }
              }
            }
          }

          resources {
            requests = {
              cpu    = each.value.resources.requests.cpu
              memory = each.value.resources.requests.memory
            }
            limits = {
              cpu    = each.value.resources.limits.cpu
              memory = each.value.resources.limits.memory
            }
          }

          dynamic "readiness_probe" {
            for_each = each.value.create_probes ? [1] : []
            content {
              http_get {
                path = each.value.health_path
                port = each.value.port
              }
              initial_delay_seconds = 10
              period_seconds        = 5
            }
          }

          dynamic "liveness_probe" {
            for_each = each.value.create_probes ? [1] : []
            content {
              http_get {
                path = each.value.health_path
                port = each.value.port
              }
              initial_delay_seconds = 15
              period_seconds        = 10
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  for_each = { for name, svc in var.services : name => svc if svc.create_service }

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    selector = { app = each.key }

    port {
      port        = each.value.port
      target_port = each.value.port
    }

    type = "ClusterIP"
  }
}
