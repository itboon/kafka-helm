{{/*
pod.commonSpec
*/}}
{{- define "pod.commonSpec" -}}
{{- if not .context -}}
  {{- print "Missing input dict: '.context'" | fail -}}
{{- end -}}
{{- if not .component -}}
  {{- print "Missing input dict: '.component'" | fail -}}
{{- end -}}
{{- if not .name -}}
  {{- print "Missing input dict: '.name'" | fail -}}
{{- end -}}
{{- $root := .context -}}
{{- $globalValues := .context.Values.global -}}
{{- $componentValues := .component -}}
{{- $componentName := .name -}}
{{- with $componentValues -}}
{{- with .imagePullSecrets | default $globalValues.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $globalValues.hostAliases }}
hostAliases:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .terminationGracePeriodSeconds }}
terminationGracePeriodSeconds: {{ . }}
{{- end }}
serviceAccountName: {{ include "kafka.serviceAccountName" $root }}
{{- with $globalValues.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .nodeSelector | default $globalValues.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .topologySpreadConstraints| default $globalValues.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .tolerations | default $globalValues.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with include "pod.common.affinity" (dict "context" $root "component" $componentValues "name" $componentName) }}
affinity:
  {{- trim . | nindent 2 }}
{{- end }}
{{- with .dnsConfig }}
dnsConfig:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .dnsPolicy }}
dnsPolicy: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common affinity definition
Pod affinity
  - Soft prefers different nodes
  - Hard requires different nodes and prefers different availibility zones
Node affinity
  - Soft prefers given user expressions
  - Hard requires given user expressions
*/}}
{{- define "pod.common.affinity" -}}
{{- with .component.affinity -}}
  {{- toYaml . -}}
{{- else -}}
{{- $preset := .context.Values.global.affinityPreset -}}
{{- $componectName := .name -}}
{{- if not .name -}}
  {{- print "Missing input dict: '.name'" | fail -}}
{{- end -}}
{{- if (eq $preset.podAntiAffinity "soft") }}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          {{- include "kafka.selectorLabels" .context | nindent 10 }}
          component: {{ $componectName | quote }}
      topologyKey: kubernetes.io/hostname
{{- else if (eq $preset.podAntiAffinity "hard") }}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          component: {{ $componectName | quote }}
      topologyKey: topology.kubernetes.io/zone
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels:
        component: {{ $componectName | quote }}
    topologyKey: kubernetes.io/hostname
{{- end }}
{{- with $preset.nodeAffinity.matchExpressions }}
{{- if (eq $preset.nodeAffinity.type "soft") }}
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 1
    preference:
      matchExpressions:
      {{- toYaml . | nindent 6 }}
{{- else if (eq $preset.nodeAffinity.type "hard") }}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      {{- toYaml . | nindent 6 }}
{{- end }}
{{- end -}}
{{- end -}}
{{- end -}}