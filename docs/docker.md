# Docker 启动 Kafka

快速启动 Kafka:

``` shell
docker run -d --network host --name demo-kafka-server kafkace/kafka:v3.5.2
```

## 数据持久化

数据存储路径 `/opt/kafka/data`，挂载数据卷:

``` shell
docker volume create demo-kafka-data

docker run -d \
  --network host \
  --name demo-kafka-server \
  -v demo-kafka-data:/opt/kafka/data \
  kafkace/kafka:v3.5.2

```

## docker compose

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