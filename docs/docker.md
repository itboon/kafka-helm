# Docker 启动 Kafka

最简单的方式启动 Kafka:

``` shell
docker run -d --name demo-kafka-server kafkace/kafka:v3.5
```

## 端口暴露

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

## 持久化

数据存储路径 `/opt/kafka/data`，像下面这个案例一样挂载一下:

``` shell
docker volume create demo-kafka-data

docker run -d --name demo-kafka-server \
  -p 29092:29092 \
  -v demo-kafka-data:/opt/kafka/data \
  --env KAFKA_BROKER_EXTERNAL_HOST="172.16.1.149" \
  --env KAFKA_BROKER_EXTERNAL_PORT="29092" \
  kafkace/kafka:v3.5

```

## 下一步

- [环境变量和配置](/env)
- [Docker Compose 启动 Kafka](/compose)