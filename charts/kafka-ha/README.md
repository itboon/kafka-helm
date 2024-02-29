# Kafka helm chart

https://github.com/itboon/kafka-docker

## Prerequisites

- Kubernetes 1.18+
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


## 集群外访问

如果需要从集群外访问 Kafka 集群，则必须将每个 Broker 暴露到集群外，支持 `NodePort` and `LoadBalancer` 两种方式。

### Chart Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| broker.external.enabled | bool | `false` | 是否开启集群外访问 |
| broker.external.service.type | string | `NodePort` | `NodePort` or `LoadBalancer` |
| broker.external.service.annotations | object | `{}` | External serivce annotations，常用于配置 `LoadBalancer`  |
| broker.external.nodePorts | list | `[]` | 如果使用 `NodePort` 模式，至少提供一个端口号，如果端口号数量小于 Broker 副本数，则端口号自动递增 |
| broker.external.domainSuffix | string | `.kafka.example.com` | 用域名后缀为 Broker 自动生成主机名 `POD_NAME` + `域名后缀`，例如 `kafka-broker-01.kafka.example.com` |
| broker.external.hosts | list | `[]` | Broker 对外的主机名，可以是域名或IP地址，需要为每个 Broker 分配一个主机名 |

> 如果使用 `LoadBalancer` 模式，则需要为 Broker 提供域名后缀 `broker.external.domainSuffix` 或者主机名 `broker.external.hosts`，后者优先级更高。如果主机名数量小于 Broker 副本数，仍然优先为 Broker 分配 hosts 主机名，不够的用域名后缀自动生成。

``` yaml
## NodePort example
broker:
  replicaCount: 3
  external:
    enabled: true
    service:
      type: "NodePort"
      annotations: {}
    nodePorts:
      - 31050
      - 31051
      - 31052
```

``` yaml
## LoadBalancer example
## 单节点集群推荐使用主机名
broker:
  replicaCount: 1
  external:
    enabled: true
    service:
      type: "LoadBalancer"
      annotations: {}
    hosts:
      kafka-dev.example.com
```

``` yaml
## LoadBalancer example
## 高可用集群推荐用域名后缀
broker:
  replicaCount: 3
  external:
    enabled: true
    service:
      type: "LoadBalancer"
      annotations: {}
    domainSuffix: ".kafka.example.com"
```

> 部署成功后请完成域名解析配置。