# Controller Nil Pointer 修复总结

## 问题描述
使用 `--set controller.persistence.enabled="false"` 时，Helm 模板出现 nil pointer 错误：
```
Error: INSTALLATION FAILED: template: kafka-ha/templates/controller/statefulset.yaml:84:41: executing "kafka-ha/templates/controller/statefulset.yaml" at <.Values.controller>: nil pointer evaluating interface {}.controller
```

## 根本原因
当使用 `--set` 禁用某些配置时，Helm 可能完全移除整个 `controller` 对象，而不仅仅是设置 `enabled: false`。这导致模板中所有直接访问 `.Values.controller.*` 的地方都会出现 nil pointer 错误。

## 修复方案

### 1. StatefulSet 模板修复
**文件**: `charts/kafka-ha/templates/controller/statefulset.yaml`

**第64行 - containerPort**:
```yaml
# 修复前
- containerPort: {{ $.Values.controller.containerPort }}

# 修复后  
- containerPort: {{ if $.Values.controller }}{{ $.Values.controller.containerPort }}{{ else }}9093{{ end }}
```

**第84行 - mountPath**:
```yaml
# 修复前
- mountPath: {{ if hasKey .Values.controller "persistence" }}{{ .Values.controller.persistence.mountPath | default "/opt/kafka/data" }}{{ else }}"/opt/kafka/data"{{ end }}

# 修复后
- mountPath: {{ if and .Values.controller (hasKey .Values.controller "persistence") }}{{ .Values.controller.persistence.mountPath | default "/opt/kafka/data" }}{{ else }}"/opt/kafka/data"{{ end }}
```

### 2. Helpers 模板修复
**文件**: `charts/kafka-ha/templates/controller/_helpers.tpl`

**KAFKA_HEAP_OPTS**:
```yaml
# 修复前
value: {{ .Values.controller.heapOpts | quote }}

# 修复后
value: {{ if .Values.controller }}{{ .Values.controller.heapOpts | quote }}{{ else }}"-Xmx1G -Xms1G"{{ end }}
```

**KAFKA_CFG_LISTENERS**:
```yaml
# 修复前
value: "CONTROLLER://0.0.0.0:{{ .Values.controller.containerPort }}"

# 修复后
value: "CONTROLLER://0.0.0.0:{{ if .Values.controller }}{{ .Values.controller.containerPort }}{{ else }}9093{{ end }}"
```

**KAFKA_CFG_LOG_DIR**:
```yaml
# 修复前
value: {{ if hasKey .Values.controller "persistence" }}{{ .Values.controller.persistence.mountPath | default "/opt/kafka/data" | quote }}{{ else }}"/opt/kafka/data"{{ end }}

# 修复后
value: {{ if and .Values.controller (hasKey .Values.controller "persistence") }}{{ .Values.controller.persistence.mountPath | default "/opt/kafka/data" | quote }}{{ else }}"/opt/kafka/data"{{ end }}
```

**extraEnvs**:
```yaml
# 修复前
{{- with .Values.controller.extraEnvs }}
  {{- toYaml . | nindent 0 }}
{{- end }}

# 修复后
{{- if and .Values.controller .Values.controller.extraEnvs }}
  {{- toYaml .Values.controller.extraEnvs | nindent 0 }}
{{- end }}
```

## 修复模式

### 1. 简单属性访问
```yaml
{{ if .Values.controller }}{{ .Values.controller.property }}{{ else }}default_value{{ end }}
```

### 2. 嵌套对象访问
```yaml
{{ if and .Values.controller (hasKey .Values.controller "nested_key") }}{{ .Values.controller.nested_key.property }}{{ else }}default_value{{ end }}
```

## 预期行为

### 场景1: 正常配置
- `controller` 对象存在且完整
- 使用配置的值或默认值

### 场景2: 部分禁用 (persistence.enabled=false)
- `controller` 对象存在但 `persistence.enabled=false`
- 仍然可以访问其他 controller 属性

### 场景3: 完全移除 controller 配置
- `controller` 对象不存在
- 使用硬编码的默认值

## 技术优势

1. **防御性编程**: 在访问对象属性前先检查对象是否存在
2. **向后兼容**: 不影响正常的配置使用
3. **优雅降级**: 提供合理的默认值
4. **错误预防**: 避免 nil pointer 异常

## 测试命令
```bash
# 现在应该可以正常工作
helm install kafka-ha --set broker.persistence.enabled="false" --set controller.persistence.enabled="false" .
```

## 相关问题修复
这个修复解决了所有因 `controller` 对象不存在而导致的 nil pointer 错误，确保 Helm chart 在各种配置场景下都能正常工作。