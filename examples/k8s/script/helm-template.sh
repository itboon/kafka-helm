#!/bin/bash

export template_home="../statefulset"

helm_template_output() {
  local instance="$1"
  local dir="$template_home/$instance"
  mkdir -pv "$dir"
  helm template kafka \
    --namespace kafka-demo \
    -f "values/${instance}.yaml" \
    ../../../charts/kafka/  > "$dir/all.yaml"
}

helm_template_output "single"
helm_template_output "demo-without-pvc"
