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


resource "kubectl_manifest" "cwagent-serviceaccount" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  depends_on = [kubernetes_namespace.amazon-cloudwatch, kubernetes_config_map.cwagentconfig[0]]
  yaml_body = templatefile("${path.module}/yamls/cwagent-serviceaccount.yaml", {
    account_id          = var.account_id,
    cloudwatch_iam_role = aws_iam_role.cwagent-eks[0].name,
  })
}

resource "kubectl_manifest" "cwagent-daemonset" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  depends_on = [kubernetes_namespace.amazon-cloudwatch, kubectl_manifest.cwagent-serviceaccount[0], kubernetes_config_map.cwagentconfig[0], aws_iam_role_policy_attachment.cwagent-eks[0]]
  yaml_body  = file("${path.module}/yamls/cwagent-daemonset.yaml")
}