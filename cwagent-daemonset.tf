resource "kubernetes_manifest" "daemonset_cloudwatch_agent" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "DaemonSet"
    "metadata" = {
      "name" = "cloudwatch-agent"
      "namespace" = "amazon-cloudwatch"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "name" = "cloudwatch-agent"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "name" = "cloudwatch-agent"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name" = "HOST_IP"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "status.hostIP"
                    }
                  }
                },
                {
                  "name" = "HOST_NAME"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "spec.nodeName"
                    }
                  }
                },
                {
                  "name" = "K8S_NAMESPACE"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "metadata.namespace"
                    }
                  }
                },
                {
                  "name" = "CI_VERSION"
                  "value" = "k8s/1.2.1"
                },
              ]
              "image" = "amazon/cloudwatch-agent:1.245315.0"
              "name" = "cloudwatch-agent"
              "ports" = [
                {
                  "containerPort" = 8125
                  "hostPort" = 8125
                  "protocol" = "UDP"
                },
              ]
              "resources" = {
                "limits" = {
                  "cpu" = "200m"
                  "memory" = "200Mi"
                }
                "requests" = {
                  "cpu" = "200m"
                  "memory" = "200Mi"
                }
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/etc/cwagentconfig"
                  "name" = "cwagentconfig"
                },
                {
                  "mountPath" = "/rootfs"
                  "name" = "rootfs"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/var/run/docker.sock"
                  "name" = "dockersock"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/var/lib/docker"
                  "name" = "varlibdocker"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/sys"
                  "name" = "sys"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/dev/disk"
                  "name" = "devdisk"
                  "readOnly" = true
                },
              ]
            },
          ]
          "serviceAccountName" = "cloudwatch-agent"
          "terminationGracePeriodSeconds" = 60
          "volumes" = [
            {
              "configMap" = {
                "name" = "cwagentconfig"
              }
              "name" = "cwagentconfig"
            },
            {
              "hostPath" = {
                "path" = "/"
              }
              "name" = "rootfs"
            },
            {
              "hostPath" = {
                "path" = "/var/run/docker.sock"
              }
              "name" = "dockersock"
            },
            {
              "hostPath" = {
                "path" = "/var/lib/docker"
              }
              "name" = "varlibdocker"
            },
            {
              "hostPath" = {
                "path" = "/sys"
              }
              "name" = "sys"
            },
            {
              "hostPath" = {
                "path" = "/dev/disk/"
              }
              "name" = "devdisk"
            },
          ]
        }
      }
    }
  }
}
