resource "kubernetes_namespace" "amazon-cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }
}

# source: https://console.aws.amazon.com/iam/home?region=eu-west-1#/policies/arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy$jsonEditor
# and added more describe volume stuff
resource "aws_iam_policy" "eks-cloudwatch-policy" {
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "cloudwatch:PutMetricData",
            "ec2:DescribeTags",
            "ec2:DescribeVolumeAttribute",
            "ec2:DescribeVolumes",
            "ec2:DescribeVolumeStatus",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
          ]
          Effect   = "Allow"
          Resource = "*"
          Sid      = "VisualEditor0"
        },
      ]
      Version = "2012-10-17"
    }
  )
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