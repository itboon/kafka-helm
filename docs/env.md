# 环境变量

## Environment Variables

| 变量 | 默认值 | 描述 |
|-----------|-------|------|
| `KAFKA_CLUSTER_ID`           | 随机生成 | Cluster ID |
| `KAFKA_BROKER_LISTENER_PORT` | `9092` | broker 端口号，如果配置了 `KAFKA_CFG_LISTENERS` 则此项失效 |
| `KAFKA_CONTROLLER_LISTENER_PORT` | `19091` | controller 端口号，如果配置了 `KAFKA_CFG_LISTENERS` 则此项失效 |
| `KAFKA_BROKER_EXTERNAL_HOST` | null | 对外暴露的主机名，可以是域名或IP地址，如果配置了 `KAFKA_CFG_ADVERTISED_LISTENERS` 则此项失效 |
| `KAFKA_BROKER_EXTERNAL_PORT` | `29092` | 对外暴露的端口号，不能跟内部端口重复，如果配置了 `KAFKA_CFG_ADVERTISED_LISTENERS` 则此项失效 |
| `KAFKA_HEAP_OPTS` | `null` | Kafka Java Heap size. 例如: `-Xmx512m -Xms512m`|

## Kafka Configurations

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

配置案例请参考 [Docker Compose 启动 Kafka](../compose)