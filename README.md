[![CI](https://github.com/itboon/kafka-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/itboon/kafka-docker/actions/workflows/docker-publish.yml)
[![Docker pulls](https://img.shields.io/docker/pulls/kafkace/kafka)](https://hub.docker.com/r/kafkace/kafka)
[![Docker TAG](https://img.shields.io/github/v/release/itboon/kafka-docker)](https://hub.docker.com/r/kafkace/kafka/tags)
![Docker Iamge](https://img.shields.io/docker/image-size/kafkace/kafka)

- [Dockerfile](https://github.com/itboon/kafka-docker/blob/main/Dockerfile)
- [GitHub](https://github.com/itboon/kafka-docker)
- [Docker Hub](https://hub.docker.com/r/kafkace/kafka)

## 关于 Apache Kafka

Apache Kafka 是一个开源分布式事件流平台，已被数千家公司用于高性能数据管道、流分析、数据集成和关键任务应用程序。

- [wikipedia.org/wiki/Apache_Kafka](https://en.wikipedia.org/wiki/Apache_Kafka)

> 超过 80% 的财富 100 强公司信任并使用 Kafka。

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
    image: kafkace/kafka:v3.5
    # restart: always
    ports:
      - "29092:29092"
    volumes:
      - kafka-data:/opt/kafka/data
    environment:
      - KAFKA_HEAP_OPTS=-Xmx512m -Xms512m
      - KAFKA_BROKER_EXTERNAL_HOST=kafka.example.com   ## 对外暴露的主机名，可以是域名或IP地址
      - KAFKA_BROKER_EXTERNAL_PORT=29092

  ## kafka web 管理 (可选)
  kafka-ui:
    image: provectuslabs/kafka-ui:v0.7.1
    # restart: always
    ports:
      - "18080:8080"
    environment:
      - KAFKA_CLUSTERS_0_NAME=demo-kafka-server
      - KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:9092

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

- Kubernetes 1.18+
- Helm 3.3+

### 获取 helm 仓库

``` shell
helm repo add kafka-repo https://helm-charts.itboon.top/kafka
helm repo update kafka-repo
```

### 部署单节点 Kafka 集群

- 下面这个案例关闭了持久化存储，仅演示部署效果

``` shell
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set broker.combinedMode.enabled="true" \
  --set broker.persistence.enabled="false" \
  kafka-repo/kafka
```

### 将 broker 和 controller 独立部署

``` shell
helm upgrade --install kafka \
  --namespace kafka-demo \
  --create-namespace \
  --set broker.persistence.size="20Gi" \
  kafka-repo/kafka
```

> 默认已开启持久化存储。

### 部署高可用 Kafka 集群

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

> 高可用集群更多配置项请参考 [examples/values-production.yml](https://github.com/itboon/kafka-docker/raw/main/examples/values-production.yml)

### Kubernetes 集群外访问

启用 Kubernetes 集群外访问：

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
