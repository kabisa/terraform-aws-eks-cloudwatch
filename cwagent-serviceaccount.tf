resource "kubernetes_manifest" "serviceaccount_cloudwatch_agent" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "ServiceAccount"
    "metadata" = {
      "annotations" = {
        "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.account_id}:role/${aws_iam_role.cwagent-eks[0].name}"
      }
      "name" = "cloudwatch-agent"
      "namespace" = "amazon-cloudwatch"
    }
  }
}

resource "kubernetes_manifest" "clusterrole_cloudwatch_agent_role" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRole"
    "metadata" = {
      "name" = "cloudwatch-agent-role"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "pods",
          "nodes",
          "endpoints",
        ]
        "verbs" = [
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "apps",
        ]
        "resources" = [
          "replicasets",
        ]
        "verbs" = [
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "batch",
        ]
        "resources" = [
          "jobs",
        ]
        "verbs" = [
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "nodes/proxy",
        ]
        "verbs" = [
          "get",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "nodes/stats",
          "configmaps",
          "events",
        ]
        "verbs" = [
          "create",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resourceNames" = [
          "cwagent-clusterleader",
        ]
        "resources" = [
          "configmaps",
        ]
        "verbs" = [
          "get",
          "update",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "clusterrolebinding_cloudwatch_agent_role_binding" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRoleBinding"
    "metadata" = {
      "name" = "cloudwatch-agent-role-binding"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind" = "ClusterRole"
      "name" = "cloudwatch-agent-role"
    }
    "subjects" = [
      {
        "kind" = "ServiceAccount"
        "name" = "cloudwatch-agent"
        "namespace" = "amazon-cloudwatch"
      },
    ]
  }
}
