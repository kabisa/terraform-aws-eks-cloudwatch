resource "aws_cloudwatch_log_group" "container_insights" {
  count    = var.enable_cloudwatch_agent ? 1 : 0
  for_each = toset(["application", "dataplane", "host", "performance"])

  name              = "/aws/containerinsights/${var.eks_cluster_name}/${each.value}"
  retention_in_days = var.log_retention_in_days
}

# this log group is specifically used bu fluentbit, by creating it here we do not have to specify the retention inside the helm chart
# Added benefit is that we can destroy it using terraform which we wouldn't be able to when using helm
resource "aws_cloudwatch_log_group" "fluentbit" {
  count             = var.enable_fluentbit ? 1 : 0
  name              = "/aws/eks/fluentbit-cloudwatch/logs"
  retention_in_days = var.log_retention_in_days
}