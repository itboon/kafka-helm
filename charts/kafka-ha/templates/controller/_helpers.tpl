
{{/*
controller.containerEnv
*/}}
{{- define "controller.containerEnv" -}}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: KAFKA_HEAP_OPTS
  value: {{ if .Values.controller }}{{ .Values.controller.heapOpts | quote }}{{ else }}"-Xmx1G -Xms1G"{{ end }}
- name: KAFKA_CFG_PROCESS_ROLES
  value: controller
- name: KAFKA_CFG_LISTENERS
  value: "CONTROLLER://0.0.0.0:{{ if .Values.controller }}{{ .Values.controller.containerPort }}{{ else }}9093{{ end }}"
- name: KAFKA_CFG_CONTROLLER_LISTENER_NAMES
  value: CONTROLLER
- name: KAFKA_CFG_CONTROLLER_QUORUM_VOTERS
  value: {{ include "kafka.controller.quorum.voters" . }}
- name: KAFKA_CFG_LOG_DIR
  value: {{ if and .Values.controller (hasKey .Values.controller "persistence") }}{{ .Values.controller.persistence.mountPath | default "/opt/kafka/data" | quote }}{{ else }}"/opt/kafka/data"{{ end }}
- name: KAFKA_CLUSTER_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "kafka.clusterId.SecretName" . }}
      key: clusterId
- name: KAFKA_NODE_ID
  value: "podnameSuffix"
{{- if and .Values.controller .Values.controller.extraEnvs }}
  {{- toYaml .Values.controller.extraEnvs | nindent 0 }}
{{- end }}
{{- end }}