# Helm 部署 Kafka

## Prerequisites

- Kubernetes 1.18+
- Helm 3.3+

## 添加 helm 仓库

``` shell
helm repo add kafka-repo https://helm-charts.itboon.top/kafka
helm repo update kafka-repo
```

## helm 部署

### 部署单节点集群

- 下面这个案例关闭了持久化存储，仅演示部署效果

``` shell
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set broker.combinedMode.enabled="true" \
  --set broker.persistence.enabled="false" \
  kafka-repo/kafka
```

### Controller 与 Broker 分离部署

``` shell
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set broker.persistence.size="20Gi" \
  kafka-repo/kafka
```

> 默认已开启持久化存储。

### 部署高可用集群

``` shell
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set controller.replicaCount="3" \
  --set broker.replicaCount="3" \
  --set broker.heapOpts="-Xms4096m -Xmx4096m" \
  --set broker.resources.requests.memory="8Gi" \
  --set broker.resources.limits.memory="16Gi" \
  kafka-repo/kafka
```

> 更多 values 请参考 [examples/values-production.yml](https://github.com/itboon/kafka-docker/raw/main/examples/values-production.yml)

### LoadBalancer 外部暴露

开启 Kubernetes 集群外访问：

``` shell
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set broker.external.enabled="true" \
  --set broker.external.service.type="LoadBalancer" \
  --set broker.external.domainSuffix="kafka.example.com" \
  kafka-repo/kafka
```

上面部署成功后请完成域名解析配置。

### Chart Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| broker.combinedMode.enabled | bool | `false` | Whether to enable the combined mode |

``` yaml
broker:
  combinedMode:
    enabled: true
  replicaCount: 1
  heapOpts: "-Xms1024m -Xmx1024m"
  persistence:
    enabled: true
    size: 20Gi
```

## 集群外访问

In order to connect to the Kafka server outside the cluster, each Broker must be exposed and `advertised.listeners` must be correctly configured.

There are two ways to expose, `NodePort` and `LoadBalancer`, each broker node needs a `NodePort` or `LoadBalancer`.

### Chart Values

| Key | Type | 默认值 | 描述 |
|-----|------|---------|-------------|
| broker.external.enabled | bool | `false` | 是否开启集群外访问 |
| broker.external.service.type | string | `NodePort` | `NodePort` or `LoadBalancer` |
| broker.external.service.annotations | object | `{}` | External serivce annotations |
| broker.external.nodePorts | list | `[]` | NodePort 模式，至少提供一个端口号，如果端口数量少于 broker 数量，则自增 |
| broker.external.domainSuffix | string | `kafka.example.com` | If you use `LoadBalancer` for external access, you must use a domain name. The external domain name corresponding to the broker is `POD_NAME` + `domain name suffix`, such as `kafka-broker-0.kafka.example.com`. After the deployment, you need to complete the domain name resolution operation |

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
broker:
  replicaCount: 3
  external:
    enabled: true
    service:
      type: "LoadBalancer"
      annotations: {}
    domainSuffix: "kafka.example.com"
```
