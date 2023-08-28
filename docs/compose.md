# Docker Compose 启动 Kafka

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
      ## 将下面 ${KAFKA_BROKER_EXTERNAL_HOST} 替换成你自己的外部主机名，可以是域名或端口
      ## - KAFKA_BROKER_EXTERNAL_HOST=kafka.example.com
      - KAFKA_BROKER_EXTERNAL_HOST=${KAFKA_BROKER_EXTERNAL_HOST}
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

传入 `KAFKA_BROKER_EXTERNAL_HOST` 变量后，启动脚本会修改相关网络配置，例如 `listeners`、`advertised.listeners`、`listener.security.protocol.map`，详情请参考[环境变量和配置](./env)

## 高级网络配置

下面这个案例列出了详细的 Kafka 网络配置，部署后的效果与上文的案例是等效的。

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
      - KAFKA_HEAP_OPTS=-Xmx1024m -Xms1024m
      - KAFKA_CFG_INTER_BROKER_LISTENER_NAME=INTERNAL
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      - KAFKA_CFG_LISTENERS=CONTROLLER://:9091,INTERNAL://:9092,EXTERNAL://:29092
      ## 将下面 ${KAFKA_BROKER_EXTERNAL_HOST} 替换成你自己的外部主机名，可以是域名或端口
      - KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://:9092,EXTERNAL://${KAFKA_BROKER_EXTERNAL_HOST}:29092
      - KAFKA_CFG_NODE_ID=1
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka:9091

  ## kafka web 管理 (可选)
  kafka-ui:
    image: provectuslabs/kafka-ui:v0.7.1
    # restart: always
    ports:
      - "18080:8080"
    environment:
      - KAFKA_CLUSTERS_0_NAME=kafka-demo
      - KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:9092
      #- KAFKA_CLUSTERS_0_READONLY=true

### 内部网络
## broker 默认内部端口 9092
## bootstrap-server: kafka:9092

### 外部网络
## broker 默认外部端口 29092
## bootstrap-server: ${KAFKA_BROKER_EXTERNAL_HOST}:29092

```
