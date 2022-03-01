resource "aws_iam_role" "fluentd-cloudwatch" {
  count = var.enable_logs_forwarding ? 1 : 0
  name  = "fluentd-cloudwatch"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${var.oidc_host_path}:aud" = "sts.amazonaws.com"
            }
          }
          Effect = "Allow"
          Principal = {
            Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_host_path}"
          }
        }
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "fluentd-cloudwatch" {
  count      = var.enable_logs_forwarding ? 1 : 0
  role       = aws_iam_role.fluentd-cloudwatch[0].name
  policy_arn = aws_iam_policy.eks-cloudwatch-policy.arn
}

locals {
  fluent_d_manifests = var.enable_logs_forwarding ? (
    split("---", templatefile("${path.module}/yamls/cloudwatch-fluentd.yaml", {
      account_id            = var.account_id,
      fluentd_iam_role_name = aws_iam_role.fluentd-cloudwatch[0].name,
    }))
  ) : []
}

resource "kubectl_manifest" "cloudwatch-fluent-d" {
  for_each   = { for manifest in local.fluent_d_manifests : md5(manifest) => manifest }
  yaml_body  = each.value

  depends_on = [
    kubernetes_namespace.amazon-cloudwatch,
    kubernetes_config_map.cluster-info,
    aws_iam_role_policy_attachment.fluentd-cloudwatch[0]
  ]
}
