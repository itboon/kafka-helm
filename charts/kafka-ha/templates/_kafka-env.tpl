{{/*
KAFKA broker domainSuffix
*/}}
{{- define "kafka.broker.domainSuffix" -}}
{{- $serviceName := include "kafka.broker.headless.serviceName" . -}}
{{- $namespace := .Release.Namespace -}}
{{- $clusterDomain := ( include "kafka.clusterDomain" .) -}}
{{- printf "%s.%s.svc.%s" $serviceName $namespace $clusterDomain -}}
{{- end -}}

{{/*
KAFKA_CFG_CONTROLLER_QUORUM_VOTERS
*/}}
{{- define "kafka.controller.quorum.voters" -}}
{{- $controllerReplicaCount := int .Values.controller.replicaCount }}
{{- $controllerFullName := include "kafka.controller.fullname" . }}
{{- $serviceName := include "kafka.controller.headless.serviceName" . }}
{{- if (eq (include "kafka.combinedMode" .) "true") }}
  {{- $controllerReplicaCount = int .Values.broker.replicaCount }}
  {{- $controllerFullName = include "kafka.broker.fullname" . }}
  {{- $serviceName = include "kafka.broker.headless.serviceName" . }}
{{- end }}
{{- $namespace := .Release.Namespace -}}
{{- $clusterDomain := ( include "kafka.clusterDomain" .) -}}
{{- $port := int .Values.containerPort.controller }}
{{- $suffix := printf "%s.%s.svc.%s:%d" $serviceName $namespace $clusterDomain $port -}}
  {{- $servers := list -}}
  {{- range $i := until $controllerReplicaCount -}}
    {{- $servers = printf "%d@%s-%d.%s" $i $controllerFullName $i $suffix | append $servers -}}
  {{- end -}}
{{ join "," $servers }}
{{- end -}}

{{/*
KAFKA Broker Componet label
*/}}
{{- define "kafka.broker.componet" -}}
{{- if (eq (include "kafka.combinedMode" .) "true") -}}
  {{- print "broker_controller" -}}
{{- else -}}
  {{- print "broker" -}}
{{- end -}}
{{- end -}}

{{/*
controller env
*/}}
{{- define "kafka.controller.containerEnv" -}}
- name: KAFKA_HEAP_OPTS
  value: {{ .Values.controller.heapOpts | quote }}
- name: KAFKA_CFG_PROCESS_ROLES
  value: controller
- name: KAFKA_CFG_LISTENERS
  value: "CONTROLLER://0.0.0.0:{{ .Values.containerPort.controller }}"
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
  {{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
broker env
*/}}
{{- define "kafka.broker.containerEnv" -}}
- name: POD_HOST_IP
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: KAFKA_HEAP_OPTS
  value: {{ .Values.broker.heapOpts | quote }}
- name: KAFKA_CFG_PROCESS_ROLES
  {{- if (eq (include "kafka.combinedMode" .) "true") }}
  value: "broker,controller"
  {{- else }}
  value: "broker"
  {{- end }}
- name: KAFKA_CFG_LISTENERS
  {{- if (eq (include "kafka.combinedMode" .) "true") }}
  value: "BROKER://0.0.0.0:{{ .Values.containerPort.broker }},EXTERNAL://0.0.0.0:{{ .Values.containerPort.brokerExternal }},CONTROLLER://0.0.0.0:{{ .Values.containerPort.controller }}"
  {{- else }}
  value: "BROKER://0.0.0.0:{{ .Values.containerPort.broker }},EXTERNAL://0.0.0.0:{{ .Values.containerPort.brokerExternal }}"
  {{- end }}
- name: KAFKA_CFG_ADVERTISED_LISTENERS
  {{- $domainSuffix := (include "kafka.broker.domainSuffix" .) }}
  value: "BROKER://$(POD_NAME).{{ $domainSuffix }}:{{ .Values.containerPort.broker }}"
{{- if .Values.broker.external.enabled }}
- name: KAFKA_EXTERNAL_SERVICE_TYPE
  value: {{ .Values.broker.external.service.type | quote }}
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
{{- $replicaCount := .Values.broker.replicaCount | int }}
{{- if and $replicaCount (ge $replicaCount 3) }}
- name: KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR
  value: "3"
- name: KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR
  value: "3"
- name: KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR
  value: "2"
{{- end }}
- name: KAFKA_CLUSTER_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "kafka.clusterId.SecretName" . }}
      key: clusterId
- name: KAFKA_NODE_ID
  value: "podnameSuffix"
- name: KAFKA_BASE_CONF_FILE
  value: {{ include "kafka.broker.baseConfigFile" . }}
{{- if (eq (include "kafka.combinedMode" .) "false") }}
- name: KAFKA_NODE_ID_OFFSET
  value: "1000"
{{- end }}
{{- with .Values.broker.extraEnvs }}
  {{- toYaml . | nindent 0 }}
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
{{- if (eq (include "kafka.combinedMode" .) "true") }}
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
{{- $brokerFullName := include "kafka.broker.fullname" . -}}
{{- $domainSuffix := (include "kafka.broker.domainSuffix" .) -}}
{{- $brokerPort := .Values.containerPort.broker | int -}}
  {{- $servers := list -}}
  {{- $brokerReplicaCount := int .Values.broker.replicaCount -}}
  {{- range $i := until $brokerReplicaCount -}}
    {{- $servers = printf "%s-%d.%s:%d" $brokerFullName $i $domainSuffix $brokerPort | append $servers -}}
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
{{- $hosts := .Values.broker.external.hosts -}}
{{- $indexLastHosts:= (sub (len $hosts) 1) | int -}}
{{- $replicaCount := .Values.broker.replicaCount | int -}}
  {{- $nodePorts := list -}}
  {{- $nodePortServers := list -}}
  {{- range (include "kafka.fullNodePorts" . | split ",") -}}
    {{- $nodePorts = printf "%s" . | append $nodePorts -}}
  {{- end -}}
  {{- range $i := until $replicaCount -}}
    {{- if le $i $indexLastHosts -}}
      {{- $servers = printf "%s:%d" (index $hosts $i) $servicePort | append $servers -}}
    {{- else -}}
      {{- $servers = printf "%s-%d%s:%d" $brokerFullname $i $domain $servicePort | append $servers -}}
    {{- end -}}
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
