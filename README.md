[![CI](https://github.com/itboon/kafka-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/itboon/kafka-docker/actions/workflows/docker-publish.yml)
[![Docker pulls](https://img.shields.io/docker/pulls/kafkace/kafka)](https://hub.docker.com/r/kafkace/kafka)
![Docker Iamge](https://img.shields.io/docker/image-size/kafkace/kafka)

- [Dockerfile](https://github.com/itboon/kafka-docker/blob/main/Dockerfile)
- [GitHub](https://github.com/itboon/kafka-docker)
- [Docker Hub](https://hub.docker.com/r/kafkace/kafka)

## 关于 Apache Kafka

[Apache Kafka](https://kafka.apache.org/) 是一个开源分布式事件流平台，已被数千家公司用于高性能数据管道、流分析、数据集成和关键任务应用程序。

## 为何选择这个镜像

- 全面兼容 `KRaft`, 不依赖 ZooKeeper
- 灵活使用环境变量进行配置覆盖
- 上手简单
- 提供 `helm chart`，你可以在 Kubernetes 快速部署高可用 Kafka 集群

## 启动 kafka 服务器

最简单的方式启动 Kafka:

``` shell
docker run -d --name demo-kafka-server kafkace/kafka:v3.5
```

### 端口暴露

跨主机访问需要开启外部网络：

``` shell
docker run -d --name demo-kafka-server \
  -p 29092:29092 \
  --env KAFKA_BROKER_EXTERNAL_HOST="172.16.1.149" \
  --env KAFKA_BROKER_EXTERNAL_PORT="29092" \
  kafkace/kafka:v3.5
```

- broker 默认内部端口 `9092`
- `KAFKA_BROKER_EXTERNAL_HOST`, 对外暴露的主机名，可以是域名或IP地址
- `KAFKA_BROKER_EXTERNAL_PORT`, 对外暴露的端口号，不能跟内部端口重复

> 在没有提供 `KAFKA_BROKER_EXTERNAL_HOST` 的情况下，仅通过 docker 对外暴露端口是无效的。

### 持久化数据存储

``` shell
docker volume create kafka-data

docker run -d --name demo-kafka-server \
  -p 29092:29092 \
  -v kafka-data:/opt/kafka/data \
  --env KAFKA_BROKER_EXTERNAL_HOST="172.16.1.149" \
  --env KAFKA_BROKER_EXTERNAL_PORT="29092" \
  kafkace/kafka:v3.5

```

## Docker Compose 启动 Kafka

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
      ## 将下面 ${KAFKA_BROKER_EXTERNAL_HOST} 替换成你自己的外部主机名，可以是域名或IP地址
      ## KAFKA_BROKER_EXTERNAL_HOST: kafka-broker-01.example.com
      KAFKA_BROKER_EXTERNAL_HOST: ${KAFKA_BROKER_EXTERNAL_HOST}
      # KAFKA_BROKER_EXTERNAL_PORT: "29092"

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


### 内部网络
## broker 默认内部端口 9092
## bootstrap-server: kafka:9092

### 外部网络
## broker 默认外部端口 29092
## bootstrap-server: ${KAFKA_BROKER_EXTERNAL_HOST}:29092

```

## Environment Variables

| 变量 | 默认值 | 描述 |
|-----------|-------|------|
| `KAFKA_CLUSTER_ID`           | 随机生成 | Cluster ID |
| `KAFKA_BROKER_LISTENER_PORT` | `9092` | broker 端口号，如果配置了 `KAFKA_CFG_LISTENERS` 则此项失效 |
| `KAFKA_CONTROLLER_LISTENER_PORT` | `19091` | controller 端口号，如果配置了 `KAFKA_CFG_LISTENERS` 则此项失效 |
| `KAFKA_BROKER_EXTERNAL_HOST` | null | 对外暴露的主机名，可以是域名或IP地址，如果配置了 `KAFKA_CFG_ADVERTISED_LISTENERS` 则此项失效 |
| `KAFKA_BROKER_EXTERNAL_PORT` | `29092` | 对外暴露的端口号，不能跟内部端口重复，如果配置了 `KAFKA_CFG_ADVERTISED_LISTENERS` 则此项失效 |
| `KAFKA_HEAP_OPTS` | `null` | Kafka Java Heap size. 例如: `-Xmx512m -Xms512m`|

### Kafka Configurations

所有以 `KAFKA_CFG_` 开头的环境变量都将映射到其相应的 Apache Kafka 配置项。

例如 `KAFKA_CFG_LISTENERS` 对应配置参数 `listeners`，`KAFKA_CFG_ADVERTISED_LISTENERS` 对应配置参数 `advertised.listeners`

Variable examples:

| 变量 | 配置项 |
|---------|--------|
| `KAFKA_CFG_PROCESS_ROLES`     | `process.roles` |
| `KAFKA_CFG_LISTENERS`         | `listeners` |
| `KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP`     | `listener.security.protocol.map` |
| `KAFKA_CFG_ADVERTISED_LISTENERS`               | `advertised.listeners` |
| `KAFKA_CFG_CONTROLLER_QUORUM_VOTERS`           | `controller.quorum.voters` |
| `KAFKA_CFG_LOG_RETENTION_HOURS`                | `log.retention.hours` |

> `log.dir` 和 `log.dirs` 已经被锁定，无法使用环境变量进行覆盖。

## helm chart 部署

### Prerequisites

- Kubernetes 1.22+
- Helm 3.3+

### 获取 helm 仓库

``` shell
helm repo add kafka-repo https://helm-charts.itboon.top/kafka
helm repo update kafka-repo
```

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


### 集群外访问

请参考 <https://github.com/itboon/kafka-docker/blob/main/docs/external.md>
