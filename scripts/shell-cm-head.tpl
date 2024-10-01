{{- $componet := "broker" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "kafka.entrypoint.configmapName" . }}
  namespace: {{ include "kafka.namespace" $ }}
  labels:
    {{- include "kafka.labels" $ | nindent 4 }}
    component: {{ $componet | quote }}
data:
  entrypoint.sh: |
