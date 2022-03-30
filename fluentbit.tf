resource "aws_iam_role" "fluentbit" {
  count       = var.enable_fluentbit ? 1 : 0
  name        = "fluentbit"
  description = "IAM role used by fluentbit inside EKS clusters"
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

resource "aws_iam_policy" "fluentbit" {
  count = var.enable_fluentbit ? 1 : 0
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "cloudwatch:PutMetricData",
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

resource "aws_iam_role_policy_attachment" "fluentbit" {
  count      = var.enable_fluentbit ? 1 : 0
  role       = aws_iam_role.fluentbit[0].name
  policy_arn = aws_iam_policy.fluentbit[0].arn
}

data "template_file" "fluentbit" {
  count    = var.enable_fluentbit ? 1 : 0
  template = file("${path.module}/yamls/fluentbit-values.yaml")
  vars = {
    region       = var.region
    iam_role_arn = aws_iam_role.fluentbit[0].arn
  }
}

resource "helm_release" "fluentbit" {
  count      = var.enable_fluentbit ? 1 : 0
  name       = "fluentbit"
  namespace  = "amazon-cloudwatch"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.14" # appVersion: v2.21.5

  values = [data.template_file.fluentbit[0].rendered]
}