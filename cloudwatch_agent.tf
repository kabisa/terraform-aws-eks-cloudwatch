data "template_file" "cloudwatch-agent" {
  count = var.enable_cloudwatch_agent ? 1 : 0
  template = file("${path.module}/yamls/cloudwatch-agent-values.yaml")
  vars = {
    clusterName = var.eks_cluster_name
  }
}

resource "helm_release" "cloudwatch-agent" {
  count = var.enable_cloudwatch_agent ? 1 : 0
  name       = "cloudwatch"
  namespace  = "amazon-cloudwatch"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = "0.0.6" # appVersion: v1.247345

  values = [data.template_file.cloudwatch-agent[0].rendered]
}