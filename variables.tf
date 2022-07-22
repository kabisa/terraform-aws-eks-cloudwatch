variable "account_id" {
  type        = string
  description = "The AWS account ID"
}

variable "oidc_host_path" {
  type = string
}

variable "region" {
  type        = string
  description = "The AWS region to deploy to"
}

variable "enable_cloudwatch_agent" {
  type        = bool
  description = "Boolean to enable cloudwatch agent"
}

variable "enable_fluentbit" {
  type        = bool
  description = "Boolean to enable fluentbit"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "log_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 90
}

variable "log_preserve_legacy_log_group" {
  description = "When true, preserves the legacy log group. Mainly useful to transition to the new log group format"
  type        = bool
  default     = true
}
