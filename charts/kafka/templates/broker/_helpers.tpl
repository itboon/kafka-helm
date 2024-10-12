{{/*
broker.containerPorts
*/}}
{{- define "broker.containerPorts" -}}
- containerPort: {{ .Values.broker.containerPort }}
  name: broker
  protocol: TCP
{{- with .Values.broker.external }}
{{- if .enabled }}
- containerPort: {{ .containerPort }}
  name: external
  protocol: TCP
  {{- if eq .type "HostPort" }}
  hostPort: {{ .hostPort | default .containerPort }}
  {{- end }}
{{- end }}
{{- end }}
{{- if not .Values.controller.enabled }}
- containerPort: {{ .Values.controller.containerPort }}
  name: controller
  protocol: TCP
{{- end }}
{{- end }}

{{/*
broker.headless.serviceAddr
*/}}
{{- define "broker.headless.serviceAddr" -}}
{{- $serviceName := include "kafka.broker.headless.serviceName" . -}}
{{- $namespace := include "kafka.namespace" . -}}
{{- $clusterDomain := ( include "kafka.clusterDomain" .) -}}
{{- printf "%s.%s.svc.%s" $serviceName $namespace $clusterDomain -}}
{{- end -}}

{{/*
broker.externalDns.enabled
*/}}
{{- define "broker.externalDns.enabled" -}}
{{- $enabled := "false" -}}
  {{- with .Values.broker.external -}}
  {{- if and .enabled .externalDns .externalDns.enabled .externalDns.domain -}}
  {{- $enabled = "true" -}}
  {{- end -}}
  {{- end -}}
{{- printf "%s" $enabled -}}
{{- end -}}

{{/*
broker.externalDns.domain
*/}}
{{- define "broker.externalDns.domain" -}}
{{- if eq (include "broker.externalDns.enabled" .) "true" -}}
{{- trimPrefix "." .Values.broker.external.externalDns.domain -}}
{{- else -}}
{{- print "" -}}
{{- end -}}
{{- end -}}

{{/*
broker.externalDns.hostnamePrefix
*/}}
{{- define "broker.externalDns.hostnamePrefix" -}}
{{- if .Values.broker.external.externalDns.hostnamePrefix -}}
{{- .Values.broker.external.externalDns.hostnamePrefix -}}
{{- else -}}
{{- printf "%s-%s" (include "kafka.fullname" .) .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
broker.advertisedListeners.internal
*/}}
{{- define "broker.advertisedListeners.internal" -}}
{{- $serviceAddr := (include "broker.headless.serviceAddr" .) -}}
{{- $port := .Values.broker.containerPort | int -}}
{{- printf "BROKER://$(POD_NAME).%s:%d" $serviceAddr $port -}}
{{- end -}}

{{/*
broker.advertisedListeners.external
*/}}
{{- define "broker.advertisedListeners.external" -}}
{{- $addr := "$(POD_IP)" -}}
{{- $port := .Values.broker.external.containerPort | int -}}
{{- with .Values.broker.external -}}
{{- if eq .type "NodePort" -}}
  {{- $addr = "$(POD_HOST_IP)" -}}
{{- else if eq .type "HostPort" -}}
  {{- $addr = "$(POD_HOST_IP)" -}}
  {{- $port = .hostPort | default .containerPort -}}
{{- end -}}
{{- if eq (include "broker.externalDns.enabled" $) "true" -}}
  {{- $addr = printf "$(POD_NAME).%s.%s" (include "broker.externalDns.hostnamePrefix" $) (include "broker.externalDns.domain" $) -}}
{{- end -}}
{{- end -}}
{{- printf "EXTERNAL://%s:%d" $addr ($port | int) -}}
{{- end -}}

{{/*
broker.config.advertised.listeners
*/}}
{{- define "broker.config.advertised.listeners" -}}
{{- printf "%s,%s" (include "broker.advertisedListeners.internal" .) (include "broker.advertisedListeners.external" .) -}}
{{- end -}}

{{/*
broker env
*/}}
{{- define "broker.containerEnv" -}}
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
  {{- if not .Values.controller.enabled }}
  value: "broker,controller"
  {{- else }}
  value: "broker"
  {{- end }}
- name: KAFKA_CFG_LISTENERS
  {{- if not .Values.controller.enabled }}
  value: "BROKER://0.0.0.0:{{ .Values.broker.containerPort }},EXTERNAL://0.0.0.0:{{ .Values.broker.external.containerPort }},CONTROLLER://0.0.0.0:{{ .Values.controller.containerPort }}"
  {{- else }}
  value: "BROKER://0.0.0.0:{{ .Values.broker.containerPort }},EXTERNAL://0.0.0.0:{{ .Values.broker.external.containerPort }}"
  {{- end }}
- name: KAFKA_CFG_ADVERTISED_LISTENERS
  value: {{ include "broker.config.advertised.listeners" . }}
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
  value: "{{ index .Values.broker.config "offsets.topic.replication.factor" | default "3" }}"
- name: KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR
  value: "{{ index .Values.broker.config "transaction.state.log.replication.factor" | default "3" }}"
- name: KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR
  value: "{{ index .Values.broker.config "transaction.state.log.min.isr" | default "2" }}"
{{- end }}
- name: KAFKA_CLUSTER_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "kafka.clusterId.SecretName" . }}
      key: clusterId
- name: KAFKA_NODE_ID
  value: "podnameSuffix"
- name: KAFKA_BASE_CONF_FILE
  value: "/etc/kafka/base-cm/server.properties"
{{- if .Values.controller.enabled }}
- name: KAFKA_NODE_ID_OFFSET
  value: "1000"
{{- end }}
{{- if .Values.broker.external.enabled -}}
{{- include "broker.externalEnv" $ | nindent 0 }}
{{- end }}
{{- with .Values.broker.extraEnvs }}
  {{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
broker.externalEnv
*/}}
{{- define "broker.externalEnv" -}}
{{- with .Values.broker.external -}}
{{- if and .enabled .type -}}
- name: KAFKA_EXTERNAL_TYPE
  value: {{ .type | quote }}
- name: KAFKA_CONFIG_INIT_SH_PATH
  value: /etc/kafka/base-cm/broker-config-init.sh
{{- $autoDiscoveryEnabled := eq (include "broker.external.autoDiscovery.enabled" $) "true" }}
{{- if and (eq .type "NodePort") (not $autoDiscoveryEnabled) }}
- name: KAFKA_EXTERNAL_ADVERTISED_PORTS
  value: {{ include "broker.fullNodePorts" $ | quote }}
{{- end }}
{{- if eq .type "LoadBalancer" }}
  {{- if eq (include "broker.externalDns.enabled" $) "true" }}
- name: KAFKA_EXTERNAL_DOMAIN
  value: {{ include "broker.externalDns.domain" $ }}
- name: KAFKA_EXTERNAL_HOSTNAME_PREFIX
  value: {{ include "broker.externalDns.hostnamePrefix" $ }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
broker.fullNodePorts
*/}}
{{- define "broker.fullNodePorts" -}}
{{- $fullNodePorts := list -}}
{{- $defaultNodePorts := list 31050 -}}
{{- $nodeports := .Values.broker.external.nodePorts | default $defaultNodePorts -}}
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
broker.internal.bootstrapServers
*/}}
{{- define "broker.internal.bootstrapServers" -}}
{{- $brokerFullName := include "kafka.broker.fullname" . -}}
{{- $domainSuffix := (include "broker.headless.serviceAddr" .) -}}
{{- $brokerPort := .Values.broker.containerPort | int -}}
  {{- $servers := list -}}
  {{- $brokerReplicaCount := int .Values.broker.replicaCount -}}
  {{- range $i := until $brokerReplicaCount -}}
    {{- $servers = printf "%s-%d.%s:%d" $brokerFullName $i $domainSuffix $brokerPort | append $servers -}}
  {{- end -}}
{{ join "," $servers }}
{{- end -}}

{{/*
broker.external.bootstrapServers
*/}}
{{- define "broker.external.bootstrapServers" -}}
{{- $servers := list -}}
{{- $brokerFullname := include "kafka.broker.fullname" . -}}
{{- $servicePort := .Values.broker.external.service.port | int -}}
{{- $domain := include "kafka.external.domainSuffix" . -}}
{{- $hosts := .Values.broker.external.hosts | default list -}}
{{- $indexLastHosts := (sub (len $hosts) 1) | int -}}
{{- $replicaCount := .Values.broker.replicaCount | int -}}
  {{- $nodePorts := list -}}
  {{- $nodePortServers := list -}}
  {{- range (include "broker.fullNodePorts" . | split ",") -}}
    {{- $nodePorts = printf "%s" . | append $nodePorts -}}
  {{- end -}}
  {{- range $i := until $replicaCount -}}
    {{- if le $i $indexLastHosts -}}
      {{- $servers = printf "%s:%d" (index $hosts $i) $servicePort | append $servers -}}
    {{- else -}}
      {{- $servers = printf "%s-%d.%s:%d" $brokerFullname $i $domain $servicePort | append $servers -}}
    {{- end -}}
    {{- $nodePortServers = printf "KUBERNETES_NODE_IP_%d:%d" $i (index $nodePorts $i | int) | append $nodePortServers -}}
  {{- end -}}
{{- if eq .Values.broker.external.service.type "NodePort" -}}
{{ join "," $nodePortServers }}
{{- else -}}
{{ join "," $servers }}
{{- end -}}
{{- end -}}

{{/*
broker.external.advertisedListeners
*/}}
{{- define "broker.external.advertisedListeners" -}}
  {{- $addrList := list -}}
  {{- range (include "kafka.external.bootstrapServers" . | split ",") -}}
    {{- $addrList = printf "EXTERNAL://%s" . | append $addrList -}}
  {{- end -}}
{{ join "," $addrList }}
{{- end -}}

{{/*
broker.external.autoDiscovery.enabled
*/}}
{{- define "broker.external.autoDiscovery.enabled" -}}
{{- $enabled := "false" -}}
  {{- with .Values.broker.external -}}
  {{- if and .enabled .autoDiscovery .autoDiscovery.enabled -}}
  {{- $enabled = "true" -}}
  {{- end -}}
  {{- end -}}
{{- printf "%s" $enabled -}}
{{- end -}}

{{/*
broker.external.autoDiscovery.initContainer
*/}}
{{- define "broker.external.autoDiscovery.initContainer" -}}
{{- with .Values.broker.external.autoDiscovery -}}
- name: auto-discovery
  image: {{ printf "%s:%s" .image.repository .image.tag }}
  imagePullPolicy: {{ .image.pullPolicy | quote }}
  command:
    - sh
    - /etc/kafka/base-cm/auto-discovery.sh
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: KAFKA_EXTERNAL_SERVICE_NAME
      value: "$(POD_NAME)-external"
    - name: KAFKA_EXTERNAL_TYPE
      value: {{ $.Values.broker.external.type | quote }}
  {{- with .resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    #- name: auto-discovery-scripts
    #  mountPath: /init-scripts/auto-discovery.sh
    #  subPath: auto-discovery.sh
    - name: auto-discovery-shared
      mountPath: /init-shared
    - mountPath: "/etc/kafka/base-cm"
      name: base-cm
{{- end -}}
{{- end -}}
