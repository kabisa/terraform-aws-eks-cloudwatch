resource "kubernetes_namespace" "amazon-cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }
}

resource "kubernetes_config_map" "cluster-info" {
  depends_on = [kubernetes_namespace.amazon-cloudwatch]
  metadata {
    name      = "cluster-info"
    namespace = kubernetes_namespace.amazon-cloudwatch.metadata[0].name
  }
  data = {
    "cluster.name" = var.eks_cluster_name
    "logs.region"  = var.region
  }
}