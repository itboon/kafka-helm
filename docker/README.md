[![CI](https://github.com/itboon/kafka-helm/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/itboon/kafka-helm/actions/workflows/docker-publish.yml)
[![Docker pulls](https://img.shields.io/docker/pulls/kafkace/kafka)](https://hub.docker.com/r/kafkace/kafka)
![Docker Iamge](https://img.shields.io/docker/image-size/kafkace/kafka)

- [GitHub](https://github.com/itboon/kafka-helm)
- [Docker Hub](https://hub.docker.com/r/kafkace/kafka)

## Docker 启动 Kafka

快速启动 Kafka:

``` shell
docker run -d --network host --name demo-kafka-server kafkace/kafka:v3.5.2
```

### 数据持久化

数据存储路径 `/opt/kafka/data`，挂载数据卷:

``` shell
docker volume create demo-kafka-data

docker run -d \
  --network host \
  --name demo-kafka-server \
  -v demo-kafka-data:/opt/kafka/data \
  kafkace/kafka:v3.5.2

```

### docker compose

``` yaml
version: "3"

volumes:
  kafka-data: {}

services:
  kafka:
    image: kafkace/kafka:v3.5.2
    restart: always
    network_mode: "host"
    volumes:
      - kafka-data:/opt/kafka/data
    environment:
      - KAFKA_HEAP_OPTS=-Xmx1024m -Xms1024m

```

## Helm 部署 Kafka

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

## 文档目录

- [通过环境变量配置 Kafka 参数](https://github.com/itboon/kafka-helm/blob/main/docs/env.md)
- [Kafka 高级网络配置](https://github.com/itboon/kafka-helm/blob/main/docs/network.md)
- [Helm 部署 kafka](https://github.com/itboon/kafka-helm/blob/main/docs/helm.md)
- [Kubernetes 集群外访问](https://github.com/itboon/kafka-helm/blob/main/docs/external.md)
