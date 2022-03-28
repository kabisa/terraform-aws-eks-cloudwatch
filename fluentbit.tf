data "template_file" "fluentbit" {
  count = var.enable_fluentbit ? 1 : 0
  template = file("${path.module}/yamls/fluentbit-values.yaml")
  vars = {
    region = var.region
  }
}

resource "helm_release" "fluentbit" {
  count = var.enable_fluentbit ? 1 : 0
  name       = "fluentbit"
  namespace  = "amazon-cloudwatch"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.14" # appVersion: v2.21.5

  values = [data.template_file.fluentbit[0].rendered]
}