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
  # build a service account manifest map
  fluent_d_manifest_templated = templatefile("${path.module}/yamls/cloudwatch-fluentd.yaml", {
    account_id            = var.account_id,
    fluentd_iam_role_name = aws_iam_role.fluentd-cloudwatch[0].name,
  })
  fluent_d_manifest_splitted = split("---", local.fluent_d_manifest_templated)
  fluent_d_manifest_list     = var.enable_cloudwatch_agent ? local.fluent_d_manifest_splitted : []
  fluent_d_manifest_map      = { for mn in local.fluent_d_manifest_list : md5(mn) => mn }
}

resource "kubectl_manifest" "cloudwatch-fluent-d" {
  for_each   = local.fluent_d_manifest_map
  depends_on = [kubernetes_namespace.amazon-cloudwatch, kubernetes_config_map.cluster-info, aws_iam_role_policy_attachment.fluentd-cloudwatch[0]]
  yaml_body  = each.value
}