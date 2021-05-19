resource "kubernetes_manifest" "serviceaccount_fluentd" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "ServiceAccount"
    "metadata" = {
      "annotations" = {
        "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.account_id}:role/${aws_iam_role.fluentd-cloudwatch[0].name}"
      }
      "name" = "fluentd"
      "namespace" = "amazon-cloudwatch"
    }
  }
}

resource "kubernetes_manifest" "clusterrole_fluentd_role" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRole"
    "metadata" = {
      "name" = "fluentd-role"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "namespaces",
          "pods",
          "pods/logs",
        ]
        "verbs" = [
          "get",
          "list",
          "watch",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "clusterrolebinding_fluentd_role_binding" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRoleBinding"
    "metadata" = {
      "name" = "fluentd-role-binding"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind" = "ClusterRole"
      "name" = "fluentd-role"
    }
    "subjects" = [
      {
        "kind" = "ServiceAccount"
        "name" = "fluentd"
        "namespace" = "amazon-cloudwatch"
      },
    ]
  }
}

resource "kubernetes_manifest" "configmap_fluentd_config" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "containers.conf" = <<-EOT
      <source>
        @type tail
        @id in_tail_container_logs
        @label @containers
        path /var/log/containers/*.log
        exclude_path ["/var/log/containers/cloudwatch-agent*", "/var/log/containers/fluentd*"]
        pos_file /var/log/fluentd-containers.log.pos
        tag *
        read_from_head true
        <parse>
          @type json
          time_format %Y-%m-%dT%H:%M:%S.%NZ
        </parse>
      </source>
      
      <source>
        @type tail
        @id in_tail_cwagent_logs
        @label @cwagentlogs
        path /var/log/containers/cloudwatch-agent*
        pos_file /var/log/cloudwatch-agent.log.pos
        tag *
        read_from_head true
        <parse>
          @type json
          time_format %Y-%m-%dT%H:%M:%S.%NZ
        </parse>
      </source>
      
      <source>
        @type tail
        @id in_tail_fluentd_logs
        @label @fluentdlogs
        path /var/log/containers/fluentd*
        pos_file /var/log/fluentd.log.pos
        tag *
        read_from_head true
        <parse>
          @type json
          time_format %Y-%m-%dT%H:%M:%S.%NZ
        </parse>
      </source>
      
      <label @fluentdlogs>
        <filter **>
          @type kubernetes_metadata
          @id filter_kube_metadata_fluentd
        </filter>
      
        <filter **>
          @type record_transformer
          @id filter_fluentd_stream_transformer
          <record>
            stream_name $${tag_parts[3]}
          </record>
        </filter>
      
        <match **>
          @type relabel
          @label @NORMAL
        </match>
      </label>
      
      <label @containers>
        <filter **>
          @type kubernetes_metadata
          @id filter_kube_metadata
        </filter>
      
        <filter **>
          @type record_transformer
          @id filter_containers_stream_transformer
          <record>
            stream_name $${tag_parts[3]}
          </record>
        </filter>
      
        <filter **>
          @type concat
          key log
          multiline_start_regexp /^\S/
          separator ""
          flush_interval 5
          timeout_label @NORMAL
        </filter>
      
        <match **>
          @type relabel
          @label @NORMAL
        </match>
      </label>
      
      <label @cwagentlogs>
        <filter **>
          @type kubernetes_metadata
          @id filter_kube_metadata_cwagent
        </filter>
      
        <filter **>
          @type record_transformer
          @id filter_cwagent_stream_transformer
          <record>
            stream_name $${tag_parts[3]}
          </record>
        </filter>
      
        <filter **>
          @type concat
          key log
          multiline_start_regexp /^\d{4}[-/]\d{1,2}[-/]\d{1,2}/
          separator ""
          flush_interval 5
          timeout_label @NORMAL
        </filter>
      
        <match **>
          @type relabel
          @label @NORMAL
        </match>
      </label>
      
      <label @NORMAL>
        <match **>
          @type cloudwatch_logs
          @id out_cloudwatch_logs_containers
          region "#{ENV.fetch('REGION')}"
          log_group_name "/aws/containerinsights/#{ENV.fetch('CLUSTER_NAME')}/application"
          log_stream_name_key stream_name
          remove_log_stream_name_key true
          auto_create_stream true
          <buffer>
            flush_interval 5
            chunk_limit_size 2m
            queued_chunks_limit_size 32
            retry_forever true
          </buffer>
        </match>
      </label>
      
      EOT
      "fluent.conf" = <<-EOT
      @include containers.conf
      @include systemd.conf
      @include host.conf
      
      <match fluent.**>
        @type null
      </match>
      
      EOT
      "host.conf" = <<-EOT
      <source>
        @type tail
        @id in_tail_dmesg
        @label @hostlogs
        path /var/log/dmesg
        pos_file /var/log/dmesg.log.pos
        tag host.dmesg
        read_from_head true
        <parse>
          @type syslog
        </parse>
      </source>
      
      <source>
        @type tail
        @id in_tail_secure
        @label @hostlogs
        path /var/log/secure
        pos_file /var/log/secure.log.pos
        tag host.secure
        read_from_head true
        <parse>
          @type syslog
        </parse>
      </source>
      
      <source>
        @type tail
        @id in_tail_messages
        @label @hostlogs
        path /var/log/messages
        pos_file /var/log/messages.log.pos
        tag host.messages
        read_from_head true
        <parse>
          @type syslog
        </parse>
      </source>
      
      <label @hostlogs>
        <filter **>
          @type kubernetes_metadata
          @id filter_kube_metadata_host
        </filter>
      
        <filter **>
          @type record_transformer
          @id filter_containers_stream_transformer_host
          <record>
            stream_name $${tag}-$${record["host"]}
          </record>
        </filter>
      
        <match host.**>
          @type cloudwatch_logs
          @id out_cloudwatch_logs_host_logs
          region "#{ENV.fetch('REGION')}"
          log_group_name "/aws/containerinsights/#{ENV.fetch('CLUSTER_NAME')}/host"
          log_stream_name_key stream_name
          remove_log_stream_name_key true
          auto_create_stream true
          <buffer>
            flush_interval 5
            chunk_limit_size 2m
            queued_chunks_limit_size 32
            retry_forever true
          </buffer>
        </match>
      </label>
      EOT
      "systemd.conf" = <<-EOT
      <source>
        @type systemd
        @id in_systemd_kubelet
        @label @systemd
        filters [{ "_SYSTEMD_UNIT": "kubelet.service" }]
        <entry>
          field_map {"MESSAGE": "message", "_HOSTNAME": "hostname", "_SYSTEMD_UNIT": "systemd_unit"}
          field_map_strict true
        </entry>
        path /var/log/journal
        <storage>
          @type local
          persistent true
          path /var/log/fluentd-journald-kubelet-pos.json
        </storage>
        read_from_head true
        tag kubelet.service
      </source>
      
      <source>
        @type systemd
        @id in_systemd_kubeproxy
        @label @systemd
        filters [{ "_SYSTEMD_UNIT": "kubeproxy.service" }]
        <entry>
          field_map {"MESSAGE": "message", "_HOSTNAME": "hostname", "_SYSTEMD_UNIT": "systemd_unit"}
          field_map_strict true
        </entry>
        path /var/log/journal
        <storage>
          @type local
          persistent true
          path /var/log/fluentd-journald-kubeproxy-pos.json
        </storage>
        read_from_head true
        tag kubeproxy.service
      </source>
      
      <source>
        @type systemd
        @id in_systemd_docker
        @label @systemd
        filters [{ "_SYSTEMD_UNIT": "docker.service" }]
        <entry>
          field_map {"MESSAGE": "message", "_HOSTNAME": "hostname", "_SYSTEMD_UNIT": "systemd_unit"}
          field_map_strict true
        </entry>
        path /var/log/journal
        <storage>
          @type local
          persistent true
          path /var/log/fluentd-journald-docker-pos.json
        </storage>
        read_from_head true
        tag docker.service
      </source>
      
      <label @systemd>
        <filter **>
          @type kubernetes_metadata
          @id filter_kube_metadata_systemd
        </filter>
      
        <filter **>
          @type record_transformer
          @id filter_systemd_stream_transformer
          <record>
            stream_name $${tag}-$${record["hostname"]}
          </record>
        </filter>
      
        <match **>
          @type cloudwatch_logs
          @id out_cloudwatch_logs_systemd
          region "#{ENV.fetch('REGION')}"
          log_group_name "/aws/containerinsights/#{ENV.fetch('CLUSTER_NAME')}/dataplane"
          log_stream_name_key stream_name
          auto_create_stream true
          remove_log_stream_name_key true
          <buffer>
            flush_interval 5
            chunk_limit_size 2m
            queued_chunks_limit_size 32
            retry_forever true
          </buffer>
        </match>
      </label>
      
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "labels" = {
        "k8s-app" = "fluentd-cloudwatch"
      }
      "name" = "fluentd-config"
      "namespace" = "amazon-cloudwatch"
    }
  }
}

resource "kubernetes_manifest" "daemonset_fluentd_cloudwatch" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "DaemonSet"
    "metadata" = {
      "name" = "fluentd-cloudwatch"
      "namespace" = "amazon-cloudwatch"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "k8s-app" = "fluentd-cloudwatch"
        }
      }
      "template" = {
        "metadata" = {
          "annotations" = {
            "configHash" = "8915de4cf9c3551a8dc74c0137a3e83569d28c71044b0359c2578d2e0461825"
          }
          "labels" = {
            "k8s-app" = "fluentd-cloudwatch"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name" = "REGION"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "logs.region"
                      "name" = "cluster-info"
                    }
                  }
                },
                {
                  "name" = "AWS_REGION"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "logs.region"
                      "name" = "cluster-info"
                    }
                  }
                },
                {
                  "name" = "CLUSTER_NAME"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "cluster.name"
                      "name" = "cluster-info"
                    }
                  }
                },
                {
                  "name" = "CI_VERSION"
                  "value" = "k8s/1.2.1"
                },
              ]
              "image" = "fluent/fluentd-kubernetes-daemonset:v1.7.3-debian-cloudwatch-1.0"
              "name" = "fluentd-cloudwatch"
              "resources" = {
                "limits" = {
                  "memory" = "400Mi"
                }
                "requests" = {
                  "cpu" = "100m"
                  "memory" = "200Mi"
                }
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/config-volume"
                  "name" = "config-volume"
                },
                {
                  "mountPath" = "/fluentd/etc"
                  "name" = "fluentdconf"
                },
                {
                  "mountPath" = "/var/log"
                  "name" = "varlog"
                },
                {
                  "mountPath" = "/var/lib/docker/containers"
                  "name" = "varlibdockercontainers"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/run/log/journal"
                  "name" = "runlogjournal"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/var/log/dmesg"
                  "name" = "dmesg"
                  "readOnly" = true
                },
              ]
            },
          ]
          "initContainers" = [
            {
              "command" = [
                "sh",
                "-c",
                "cp /config-volume/..data/* /fluentd/etc",
              ]
              "image" = "busybox"
              "name" = "copy-fluentd-config"
              "volumeMounts" = [
                {
                  "mountPath" = "/config-volume"
                  "name" = "config-volume"
                },
                {
                  "mountPath" = "/fluentd/etc"
                  "name" = "fluentdconf"
                },
              ]
            },
            {
              "command" = [
                "sh",
                "-c",
                "",
              ]
              "image" = "busybox"
              "name" = "update-log-driver"
            },
          ]
          "serviceAccountName" = "fluentd"
          "terminationGracePeriodSeconds" = 30
          "volumes" = [
            {
              "configMap" = {
                "name" = "fluentd-config"
              }
              "name" = "config-volume"
            },
            {
              "emptyDir" = {}
              "name" = "fluentdconf"
            },
            {
              "hostPath" = {
                "path" = "/var/log"
              }
              "name" = "varlog"
            },
            {
              "hostPath" = {
                "path" = "/var/lib/docker/containers"
              }
              "name" = "varlibdockercontainers"
            },
            {
              "hostPath" = {
                "path" = "/run/log/journal"
              }
              "name" = "runlogjournal"
            },
            {
              "hostPath" = {
                "path" = "/var/log/dmesg"
              }
              "name" = "dmesg"
            },
          ]
        }
      }
    }
  }
}
