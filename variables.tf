variable "account_id" {
  type = string
}

variable "oidc_host_path" {
  type = string
}

variable "region" {
  type = string
}

variable "enable_cloudwatch_agent" {
  type = bool
}

variable "enable_logs_forwarding" {
  type = bool
}

variable "eks_cluster_name" {
  type = string
}