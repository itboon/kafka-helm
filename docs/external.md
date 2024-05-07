# Kafka Broker 容器外部网络

容器化部署 Kafka，Kafka 默认对外宣告的主机名是容器IP地址，外部主机无法直接访问容器内部网络。需要增加一个容器外部端口，并对外宣告，同时容器内部端口也需要保留，方便Kafka集群内部通信。

内外端口需要配置 `listeners` `advertised.listeners` 这两个参数，进阶版的配置案例请参考 [docker-compose-advanced.yaml](https://github.com/itboon/kafka-docker/blob/main/examples/docker-compose-advanced.yml)

本项目容器镜像已经简化了内外端口配置，内部端口默认是9092，外部网络只需要配置 `KAFKA_BROKER_EXTERNAL_HOST` `KAFKA_BROKER_EXTERNAL_PORT` 两个环境变量即可。

> 本文中`外网`、`外部网络`指的是容器外部网络，例如公有云VPC网络，数据中心私有网络。如果需要把Kafka暴露到互联网，建议做好IP白名单管理。

## Docker Compose

``` yaml
version: "3"

volumes:
  kafka-data: {}

services:
  kafka:
    image: kafkace/kafka:v3.6
    # restart: always
    ports:
      - "29092:29092"
    volumes:
      - kafka-data:/opt/kafka/data
    environment:
      KAFKA_HEAP_OPTS: "-Xms1024m -Xmx1024m"
      ## 将主机名替换成你自己的外部主机名，可以是域名或IP地址
      KAFKA_BROKER_EXTERNAL_HOST: kafka-broker-01.example.com
      KAFKA_BROKER_EXTERNAL_PORT: "29092"

  ## kafka web 管理 (可选)
  kafka-ui:
    image: provectuslabs/kafka-ui:v0.7.1
    # restart: always
    ports:
      - "18080:8080"
    environment:
      DYNAMIC_CONFIG_ENABLED: "true"
      KAFKA_CLUSTERS_0_NAME: kafka-demo
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092
      # KAFKA_CLUSTERS_0_READONLY: "true"

```

## Helm

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
      - kafka-dev.example.com
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