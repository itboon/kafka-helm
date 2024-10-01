{{/*
Expand the name of the chart.
*/}}
{{- define "kafka.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 35 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kafka.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 35 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 35 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 35 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kafka.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 35 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kafka.labels" -}}
helm.sh/chart: {{ include "kafka.chart" . }}
{{ include "kafka.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/part-of: {{ include "kafka.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kafka.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kafka.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kafka.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kafka.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "kafka.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
kafka image
*/}}
{{- define "kafka.kafkaImage" -}}
{{- $imageTag := default .Chart.AppVersion .Values.image.tag }}
{{- printf "%s:%s" .Values.image.repository $imageTag }}
{{- end }}

{{/*
kafka.entrypoint.configmapName
*/}}
{{- define "kafka.entrypoint.configmapName" -}}
{{ include "kafka.fullname" .}}-entrypoint
{{- end }}

{{/*
kafka-controller
*/}}
{{- define "kafka.controller.fullname" -}}
{{- printf "%s-controller" (include "kafka.fullname" .) }}
{{- end }}

{{/*
kafka-broker
*/}}
{{- define "kafka.broker.fullname" -}}
  {{- printf "%s-broker" (include "kafka.fullname" .) }}
{{- end }}

{{/*
kafka-ui
*/}}
{{- define "kafka.ui.fullname" -}}
{{- printf "%s-ui" (include "kafka.fullname" .) }}
{{- end }}

{{/*
kafka-exporter
*/}}
{{- define "kafka.exporter.fullname" -}}
{{- printf "%s-exporter" (include "kafka.fullname" .) }}
{{- end }}

{{/*
kafka clusterId SecretName
*/}}
{{- define "kafka.clusterId.SecretName" -}}
{{- printf "%s-cluster-id" (include "kafka.fullname" .) }}
{{- end }}

{{/*
kafka combinedMode
*/}}
{{- define "kafka.combinedMode" -}}
{{- if .Values.controller.enabled -}}
{{- print "false" -}}
{{- else -}}
{{- print "true" -}}
{{- end -}}
{{- end -}}

{{/*
kafka clusterDomain
*/}}
{{- define "kafka.clusterDomain" -}}
{{- default "cluster.local" .Values.clusterDomain -}}
{{- end -}}

{{/*
kafka broker headless serviceName
*/}}
{{- define "kafka.broker.headless.serviceName" -}}
{{- printf "%s-headless" (include "kafka.fullname" .) }}
{{- end }}


{{/*
kafka.controller.headless.serviceName
*/}}
{{- define "kafka.controller.headless.serviceName" -}}
{{- printf "%s" (include "kafka.controller.fullname" .) }}
{{- end }}

{{/*
kafka.controller.quorum.voters
*/}}
{{- define "kafka.controller.quorum.voters" -}}
{{- $fullName := include "kafka.controller.fullname" . -}}
{{- $serviceName := include "kafka.controller.headless.serviceName" . -}}
{{- $replicaCount := int .Values.controller.replicaCount -}}
{{- if not .Values.controller.enabled -}}
  {{- $replicaCount = int .Values.broker.replicaCount -}}
  {{- $fullName = include "kafka.broker.fullname" . -}}
  {{- $serviceName = include "kafka.broker.headless.serviceName" . -}}
{{- end -}}
{{- $namespace := include "kafka.namespace" . -}}
{{- $clusterDomain := include "kafka.clusterDomain" . -}}
{{- $port := int .Values.controller.containerPort -}}
{{- $suffix := printf "%s.%s.svc.%s:%d" $serviceName $namespace $clusterDomain $port -}}
  {{- $servers := list -}}
  {{- range $i := until (int $replicaCount) -}}
    {{- $servers = printf "%d@%s-%d.%s" $i $fullName $i $suffix | append $servers -}}
  {{- end -}}
{{ join "," $servers }}
{{- end -}}
