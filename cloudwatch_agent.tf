resource "kubernetes_config_map" "cwagentconfig" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  depends_on = [kubernetes_namespace.amazon-cloudwatch]
  metadata {
    name      = "cwagentconfig"
    namespace = kubernetes_namespace.amazon-cloudwatch.metadata[0].name
  }
  data = {
    "cwagentconfig.json" = <<EOT
{
    "agent": {
        "region": "${var.region}"
    },
    "logs": {
        "metrics_collected": {
            "kubernetes": {
                "cluster_name": "${var.eks_cluster_name}",
                "metrics_collection_interval": 60
            }
        },
        "force_flush_interval": 5
    },
    "metrics": {
        "metrics_collected": {
            "statsd": {
                "service_address": ":8125"
            }
        }
    }
}
EOT
  }
}

resource "aws_iam_role" "cwagent-eks" {
  count = var.enable_cloudwatch_agent ? 1 : 0
  name  = "cwagent-eks"
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
          Effect = "Allow",
          Principal = {
            Federated = "arn:aws:iam::${var.account_id}:oidc-provider/${var.oidc_host_path}"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "cwagent-eks" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  role       = aws_iam_role.cwagent-eks[0].name
  policy_arn = aws_iam_policy.eks-cloudwatch-policy.arn
}

locals {
  # build a service account manifest map
  service_account_manifest_templated = templatefile("${path.module}/yamls/cwagent-serviceaccount.yaml", {
    account_id          = var.account_id,
    cloudwatch_iam_role = var.enable_cloudwatch_agent ? aws_iam_role.cwagent-eks[0].name : "dummy",
  })
  service_account_manifest_splitted = split("---", local.service_account_manifest_templated)
  service_account_manifest_list     = var.enable_cloudwatch_agent ? local.service_account_manifest_splitted : []
  service_account_manifest_map      = { for mn in local.service_account_manifest_list : md5(mn) => mn }

  # build deamonset manifest map
  daemonset_manifest          = file("${path.module}/yamls/cwagent-daemonset.yaml")
  daemonset_manifest_splitted = split("---", local.daemonset_manifest)
  daemonset_manifest_list     = var.enable_cloudwatch_agent ? local.daemonset_manifest_splitted : []
  daemonset_manifest_map      = { for mn in local.daemonset_manifest_list : md5(mn) => mn }
}

resource "kubectl_manifest" "cwagent-serviceaccount" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  depends_on = [kubernetes_namespace.amazon-cloudwatch, kubernetes_config_map.cwagentconfig[0]]
  for_each   = local.service_account_manifest_map
  yaml_body  = each.value
}

resource "kubectl_manifest" "cwagent-daemonset" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  for_each   = local.daemonset_manifest_map
  depends_on = [kubernetes_namespace.amazon-cloudwatch, kubectl_manifest.cwagent-serviceaccount[0], kubernetes_config_map.cwagentconfig[0], aws_iam_role_policy_attachment.cwagent-eks[0]]
  yaml_body  = each.value
}
