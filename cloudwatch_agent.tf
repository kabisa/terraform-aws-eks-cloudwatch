resource "aws_iam_role" "cloudwatch-agent" {
  count       = var.enable_cloudwatch_agent ? 1 : 0
  name        = "cloudwatch-agent"
  description = "IAM role used by the cloudwatch agent inside EKS clusters"
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

resource "aws_iam_policy" "cloudwatch-agent" {
  count = var.enable_cloudwatch_agent ? 1 : 0
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

resource "aws_iam_role_policy_attachment" "cloudwatch-agent" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  role       = aws_iam_role.cloudwatch-agent[0].name
  policy_arn = aws_iam_policy.cloudwatch-agent[0].arn
}

resource "helm_release" "cloudwatch-agent" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  name       = "cloudwatch"
  namespace  = "amazon-cloudwatch"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = "0.0.9"
  # appVersion: 1.247350.0b251780

  values = [
    templatefile(
      "${path.module}/yamls/cloudwatch-agent-values.yaml",
      {
        eks_cluster_name = var.eks_cluster_name
        iam_role_arn     = aws_iam_role.cloudwatch-agent[0].arn
      }
    )
  ]
}