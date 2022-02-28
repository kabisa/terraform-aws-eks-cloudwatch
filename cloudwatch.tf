resource "aws_cloudwatch_log_group" "container_insights" {
  for_each = toset(["application", "dataplane", "host", "performance"])

  name              = "/aws/containerinsights/${var.eks_cluster_name}/${each.value}"
  retention_in_days = var.log_retention_in_days
}
