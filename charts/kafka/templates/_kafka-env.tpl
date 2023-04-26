{{/*
KAFKA_CFG_CONTROLLER_QUORUM_VOTERS
*/}}
{{- define "kafka.controller.quorum.voters" -}}
{{- $controllerPort := int .Values.containerPort.controller }}
{{- $controllerReplicaCount := int .Values.controller.replicaCount }}
{{- $controllerFullName := include "kafka.controller.fullname" . }}
{{- $serviceName := include "kafka.controller.headless.serviceName" . }}
{{- if .Values.broker.combinedMode.enabled }}
  {{- $controllerReplicaCount = int .Values.broker.replicaCount }}
  {{- $controllerFullName = include "kafka.broker.fullname" . }}
  {{- $serviceName = include "kafka.broker.headless.serviceName" . }}
{{- end }}
{{- range $i := until $controllerReplicaCount }}
  {{- if gt $i 0 }}{{ printf "," }}{{ end }}{{ printf "%d@%s-%d.%s:%d" $i $controllerFullName $i $serviceName $controllerPort }}
{{- end }}
{{- end }}

{{/*
KAFKA Broker Componet label
*/}}
{{- define "kafka.broker.componet" -}}
{{- $componet := "broker" }}
{{- if .Values.broker.combinedMode.enabled }}
  {{- $componet = "broker_controller" }}
{{- end }}
{{- $componet }}
{{- end }}

{{/*
controller env
*/}}
{{- define "kafka.controller.containerEnv" -}}
- name: KAFKA_HEAP_OPTS
  value: {{ .Values.broker.heapOpts | quote }}
- name: KAFKA_CFG_PROCESS_ROLES
  value: controller
- name: KAFKA_CFG_LISTENERS
  value: "CONTROLLER://:{{ .Values.containerPort.controller }}"
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
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- with .Values.controller.extraEnvs }}
  {{- toYaml . }}
{{- end }}
{{- end }}

{{/*
broker env
*/}}
{{- define "kafka.broker.containerEnv" -}}
{{- $replicaCount := .Values.broker.replicaCount | int -}}
- name: POD_HOST_IP
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: KAFKA_HEAP_OPTS
  value: {{ .Values.broker.heapOpts | quote }}
- name: KAFKA_CFG_PROCESS_ROLES
  {{- if .Values.broker.combinedMode.enabled }}
  value: "broker,controller"
  {{- else }}
  value: "broker"
  {{- end }}
- name: KAFKA_CFG_LISTENERS
  {{- if .Values.broker.combinedMode.enabled }}
  value: "BROKER://:{{ .Values.containerPort.broker }},EXTERNAL://:{{ .Values.containerPort.brokerExternal }},CONTROLLER://:{{ .Values.containerPort.controller }}"
  {{- else }}
  value: "BROKER://:{{ .Values.containerPort.broker }},EXTERNAL://:{{ .Values.containerPort.brokerExternal }}"
  {{- end }}
{{- if .Values.broker.external.enabled }}
- name: KAFKA_EXTERNAL_SERVICE_TYPE
  value: {{ .Values.broker.external.service.type | quote }}
- name: KAFKA_CFG_ADVERTISED_LISTENERS
  value: "BROKER://:{{ .Values.containerPort.broker }}"
- name: KAFKA_EXTERNAL_ADVERTISED_LISTENERS
  value: {{ (include "kafka.external.advertisedListeners" .) | quote }}
{{- end }}
- name: KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP
  value: CONTROLLER:PLAINTEXT,BROKER:PLAINTEXT,EXTERNAL:PLAINTEXT
- name: KAFKA_CFG_INTER_BROKER_LISTENER_NAME
  value: BROKER
- name: KAFKA_CFG_CONTROLLER_LISTENER_NAMES
  value: CONTROLLER
- name: KAFKA_CFG_CONTROLLER_QUORUM_VOTERS
  value: {{ include "kafka.controller.quorum.voters" . }}
{{- if and $replicaCount (ge $replicaCount 3) }}
- name: KAFKA_CFG_DEFAULT_REPLICATION_FACTOR
  value: "3"
- name: KAFKA_CFG_MIN_INSYNC_REPLICAS
  value: "2"
- name: KAFKA_CFG_NUM_PARTITIONS
  value: "8"
{{- end }}
- name: KAFKA_CLUSTER_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "kafka.clusterId.SecretName" . }}
      key: clusterId
- name: KAFKA_NODE_ID
  value: "podnameSuffix"
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- if not .Values.broker.combinedMode.enabled }}
- name: KAFKA_NODE_ID_OFFSET
  value: "1000"
{{- end }}
{{- with .Values.broker.extraEnvs }}
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- end }}

{{/*
broker container ports
*/}}
{{- define "kafka.broker.containerPorts" -}}
- containerPort: {{ .Values.containerPort.broker }}
  name: broker
  protocol: TCP
{{- if .Values.broker.external.enabled }}
- containerPort: {{ .Values.containerPort.brokerExternal }}
  name: external
  protocol: TCP
{{- end }}
{{- if .Values.broker.combinedMode.enabled }}
- containerPort: {{ .Values.containerPort.controller }}
  name: controller
  protocol: TCP
{{- end }}
{{- end }}

{{/*
kafka fullNodePorts
*/}}
{{- define "kafka.fullNodePorts" -}}
{{- $fullNodePorts := list -}}
{{- $nodeports := .Values.broker.external.nodePorts -}}
{{- $replicaCount := .Values.broker.replicaCount | int -}}
{{- $nodeport := (index $nodeports 0) | int -}}
{{- $indexLastNodeport := (sub (len $nodeports) 1) | int -}}
{{- $lastNodeport := (index $nodeports $indexLastNodeport) | int -}}
{{- range $i := until $replicaCount -}}
  {{- if le $i $indexLastNodeport -}}
    {{- $nodeport = (index $nodeports $i) | int -}}
  {{- else -}}
    {{- $nodeport = (add (sub $i $indexLastNodeport) $lastNodeport) | int -}}
  {{- end -}}
  {{- $fullNodePorts = printf "%d" $nodeport | append $fullNodePorts -}}
{{- end -}}
{{ join "," $fullNodePorts }}
{{- end -}}

{{/*
KAFKA BOOTSTRAPSERVERS
*/}}
{{- define "kafka.bootstrapServers" -}}
{{- $servers := list -}}
{{- $brokerPort := .Values.containerPort.broker | int -}}
{{- $brokerReplicaCount := int .Values.broker.replicaCount -}}
{{- $brokerFullName := include "kafka.broker.fullname" . -}}
{{- $serviceName := include "kafka.broker.headless.serviceName" . -}}
{{- range $i := until $brokerReplicaCount -}}
  {{- $servers = printf "%s-%d.%s:%d" $brokerFullName $i $serviceName $brokerPort | append $servers -}}
{{- end -}}
{{ join "," $servers }}
{{- end -}}

{{/*
KAFKA External BOOTSTRAPSERVERS
*/}}
{{- define "kafka.external.bootstrapServers" -}}
{{- $servers := list -}}
{{- $brokerFullname := include "kafka.broker.fullname" . -}}
{{- $servicePort := .Values.broker.external.service.port | int -}}
{{- $domain := .Values.broker.external.domainSuffix -}}
{{- $replicaCount := .Values.broker.replicaCount | int -}}
  {{- $nodePorts := list -}}
  {{- $nodePortServers := list -}}
  {{- range (include "kafka.fullNodePorts" . | split ",") -}}
    {{- $nodePorts = printf "%s" . | append $nodePorts -}}
  {{- end -}}
  {{- range $i := until $replicaCount -}}
    {{- $servers = printf "%s-%d.%s:%d" $brokerFullname $i $domain $servicePort | append $servers -}}
    {{- $nodePortServers = printf "KUBERNETES_NODE_IP_%d:%d" $i (index $nodePorts $i | int) | append $nodePortServers -}}
  {{- end -}}
{{- if eq .Values.broker.external.service.type "NodePort" -}}
{{ join "," $nodePortServers }}
{{- else if eq .Values.broker.external.service.type "LoadBalancer" -}}
{{ join "," $servers }}
{{- end -}}
{{- end -}}

{{/*
KAFKA External ADVERTISED_LISTENER
*/}}
{{- define "kafka.external.advertisedListeners" -}}
  {{- $addrList := list -}}
  {{- range (include "kafka.external.bootstrapServers" . | split ",") -}}
    {{- $addrList = printf "EXTERNAL://%s" . | append $addrList -}}
  {{- end -}}
{{ join "," $addrList }}
{{- end -}}
