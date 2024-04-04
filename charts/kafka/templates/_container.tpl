{{- define "kafka.initContainer.checkClusterId" -}}
- name: check-clusterid
  image: {{ include "kafka.kafkaImage" . | quote }}
  {{- if .Values.image.pullPolicy }}
  imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
  {{- end }}
  env:
  - name: KAFKA_CLUSTER_ID
    valueFrom:
      secretKeyRef:
        name: {{ include "kafka.clusterId.SecretName" . }}
        key: clusterId
  - name: KAFKA_CFG_LOG_DIR
    value: "/opt/kafka/data"
  command: ["/bin/bash"]
  args:
    - -c
    - |
      export Meta_File="$KAFKA_CFG_LOG_DIR/meta.properties"
      echo "[check-clusterid] $Meta_File"
      if [[ -f "$Meta_File" ]]; then
        meta_clusterid=$(grep -E '^cluster\.id' $Meta_File | awk -F '=' '{print $2}')
        if [[ "$meta_clusterid" != "$KAFKA_CLUSTER_ID" ]]; then
          cat "$Meta_File"
          echo "[ERROR] CLUSTER_ID Exception, \
            The CLUSTER_ID currently deployed is $KAFKA_CLUSTER_ID, \
            and The stored CLUSTER_ID in KAFKA_CFG_LOG_DIR is $meta_clusterid"
          echo "[WARN] You can modify the CLUSTER_ID by editing the secret. \
              kubectl -n {{ .Release.Namespace }} edit {{ include "kafka.clusterId.SecretName" . }}"
          exit "50"
        fi
      fi
  volumeMounts:
  - mountPath: /opt/kafka/data
    name: data
    readOnly: true
{{- end }}
