{{/*
notes.internal.bootstrapServers
*/}}
{{- define "notes.internal.bootstrapServers" -}}
{{- $brokerFullName := include "kafka.broker.fullname" . -}}
{{- $serviceAddr := (include "broker.headless.serviceAddr" .) -}}
{{- $brokerPort := .Values.broker.containerPort | int -}}
  {{- $servers := list -}}
  {{- $brokerCount := int .Values.broker.replicaCount -}}
    {{- if ge $brokerCount 3 -}}
    {{- $brokerCount = 3 -}}
    {{- end -}}
  {{- range $i := until $brokerCount -}}
    {{- $servers = printf "%s-%d.%s:%d" $brokerFullName $i $serviceAddr $brokerPort | append $servers -}}
  {{- end -}}
{{ join "," $servers }}
{{- end -}}

{{/*
notes.external.bootstrapServers
*/}}
{{- define "notes.external.bootstrapServers" -}}
{{- $externalType := .Values.broker.external.type -}}
{{- $port := .Values.broker.external.containerPort | toString -}}
{{- if eq (include "broker.externalDns.enabled" .) "true" -}}
{{- $hostnamePrefix := include "broker.externalDns.hostnamePrefix" . -}}
{{- $domain := (include "broker.externalDns.domain" .) -}}
  {{- $servers := list -}}
  {{- $brokerCount := int .Values.broker.replicaCount -}}
  {{- if ge $brokerCount 3 -}}
    {{- $brokerCount = 3 -}}
  {{- end -}}
  {{- if eq $externalType "NodePort" -}}
    {{- $port = "<NODE_PORT_NUMBER>" -}}
  {{- end -}}
  {{- range $i := until $brokerCount -}}
    {{- $podname := printf "%s-%d" (include "kafka.broker.fullname" $) (int $i) -}}
    {{- $server := printf "%s.%s.%s:%s" $podname $hostnamePrefix $domain $port -}}
    {{- if eq $externalType "LoadBalancer" -}}
      {{- $server = printf "%s-%d.%s:%s" $hostnamePrefix (int $i) $domain $port -}}
    {{- end -}}
    {{- $servers = append $servers $server -}}
  {{- end -}}
{{ join "," $servers }}
{{- else -}}
{{ if eq $externalType "NodePort" -}}
{{- print "<NODE_ADDRESS>:<NODE_PORT_NUMBER>" -}}
{{- else if eq $externalType "HostPort" -}}
  {{- if .Values.broker.external.hostPort -}}
  {{- $port := .Values.broker.external.hostPort | toString -}}
  {{- end -}}
  {{- printf "<NODE_ADDRESS>:%s" $port -}}
{{- else if eq $externalType "LoadBalancer" -}}
{{- printf "<LOADBALANCER_ADDRESS>:%s" $port -}}
{{- else if eq $externalType "PodIP" -}}
{{- printf "<POD_IP>:%s" $port -}}
{{- end -}}
{{- end -}}
{{- end -}}