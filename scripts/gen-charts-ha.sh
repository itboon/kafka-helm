#!/bin/bash

charts_home="../charts"
chart_ha_root="../charts/kafka-ha"

rm -rf "$chart_ha_root"
cp -a "${charts_home}/kafka" "$chart_ha_root"

set -i 's/^name: kafka$/name: kafka-ha/'  "${chart_ha_root}/Chart.yaml"

init_ha_values() {
  yq -n 'load("'${charts_home}/kafka/values.yaml'") * load("values-ha.yaml")' \
    | tee "${chart_ha_root}/values.yaml"
}

init_ha_values
