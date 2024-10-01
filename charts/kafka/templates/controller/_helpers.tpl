
{{/*
controller.containerEnv
*/}}
{{- define "controller.containerEnv" -}}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: KAFKA_HEAP_OPTS
  value: {{ .Values.controller.heapOpts | quote }}
- name: KAFKA_CFG_PROCESS_ROLES
  value: controller
- name: KAFKA_CFG_LISTENERS
  value: "CONTROLLER://0.0.0.0:{{ .Values.controller.containerPort }}"
- name: KAFKA_CFG_CONTROLLER_LISTENER_NAMES
  value: CONTROLLER
- name: KAFKA_CFG_CONTROLLER_QUORUM_VOTERS
  value: {{ include "kafka.controller.quorum.voters" . }}
- name: KAFKA_CLUSTER_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "kafka.clusterId.SecretName" . }}
      key: clusterId
- name: KAFKA_NODE_ID
  value: "podnameSuffix"
{{- with .Values.controller.extraEnvs }}
  {{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}