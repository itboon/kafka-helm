# Kafka helm chart

https://github.com/itboon/kafka-docker

## Prerequisites

- Kubernetes 1.22+
- Helm 3.3+

## 获取 helm 仓库

``` shell
helm repo add kafka-repo https://helm-charts.itboon.top/kafka
helm repo update kafka-repo
```

## 部署 Kafka

### 部署单节点 Kafka 集群

``` shell
## 下面的部署案例关闭了持久化存储，仅作为演示
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set broker.persistence.enabled="false" \
  kafka-repo/kafka
```

``` shell
## 默认已开启持久化存储
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  kafka-repo/kafka
```

### 将 broker 和 controller 分开部署

``` shell
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set broker.combinedMode.enabled="false" \
  --set controller.replicaCount="1" \
  --set broker.replicaCount="1" \
  kafka-repo/kafka
```

> `broker.combinedMode.enabled` 混部模式，即进程同时具有 broker + controller 角色，单节点服务器启动一个 Pod 即可。`kafka-repo/kafka` 默认开启混部，`kafka-repo/kafka-ha` 默认关闭混部。

### 部署高可用集群

``` shell
## kafka-repo/kafka-ha 默认部署 3 controller + 3 broker
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  kafka-repo/kafka-ha
```

``` shell
## 调整集群资源配额
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set controller.replicaCount="3" \
  --set broker.replicaCount="3" \
  --set broker.heapOpts="-Xms4096m -Xmx4096m" \
  --set broker.resources.requests.memory="8Gi" \
  --set broker.resources.limits.memory="16Gi" \
  kafka-repo/kafka-ha
```

> More values please refer to [examples/values-production.yml](https://github.com/sir5kong/kafka-docker/raw/main/examples/values-production.yml)

## Kafka Broker 配置

```yaml
## 单节点 Broker 配置
broker:
  replicaCount: 1
  config:
    num.partitions: "2"
```

```yaml
## 高可用集群推荐配置
broker:
  replicaCount: 3
  config:
    num.partitions: "6"
    default.replication.factor: "3"
    min.insync.replicas: "2"
```

> `broker.config` 某些关键配置会被环境变量覆盖，例如: node.id advertised.listeners controller.quorum.voters 等

## 集群外访问

请参考 <https://github.com/itboon/kafka-docker/blob/main/docs/external.md>
