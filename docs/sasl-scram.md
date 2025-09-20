# Kafka SASL SCRAM 认证配置指南

本文档介绍如何在 Kafka Helm Chart 中配置 SASL SCRAM 认证。

## 概述

SASL SCRAM (Salted Challenge Response Authentication Mechanism) 是一种安全的认证机制，提供了比 PLAIN 认证更强的安全性。本配置支持 SCRAM-SHA-256 机制。

## 配置说明

### 1. 启用 SASL SCRAM 认证

在 `values.yaml` 中添加以下配置：

```yaml
broker:
  auth:
    enabled: true
    mechanism: "SCRAM-SHA-256"
    users:
      - username: "kafka"
        password: "Kafka@2025"
```

### 2. 自动配置的参数

启用 SASL SCRAM 认证后，以下参数会自动配置：

- `sasl.enabled.mechanisms=SCRAM-SHA-256`
- `sasl.mechanism.inter.broker.protocol=SCRAM-SHA-256`
- `security.inter.broker.protocol=SASL_PLAINTEXT`
- `listener.security.protocol.map=CONTROLLER:PLAINTEXT,BROKER:SASL_PLAINTEXT,EXTERNAL:SASL_PLAINTEXT`

## 部署步骤

### 1. 使用示例配置部署

```bash
# 使用预配置的 SASL SCRAM 配置文件
helm install kafka-sasl ./charts/kafka -f examples/values-sasl-scram.yml

# 或者自定义配置
helm install kafka-sasl ./charts/kafka --set broker.auth.enabled=true \
  --set broker.auth.mechanism=SCRAM-SHA-256 \
  --set broker.auth.users[0].username=kafka \
  --set broker.auth.users[0].password=Kafka@2025
```

### 2. 验证部署状态

```bash
# 检查 Pod 状态
kubectl get pods -l app.kubernetes.io/name=kafka

# 检查 SCRAM 用户初始化 Job
kubectl get jobs -l app.kubernetes.io/component=broker-init

# 查看 Kafka 日志
kubectl logs -l app.kubernetes.io/component=broker
```

## 测试连接

### 1. 部署测试客户端

```bash
# 部署测试客户端 Pod
kubectl apply -f examples/kafka-client-sasl.yaml
```

### 2. 测试生产者

```bash
# 进入客户端 Pod
kubectl exec -it kafka-client-sasl -- bash

# 创建主题
bin/kafka-topics.sh --bootstrap-server kafka-sasl-broker:9092 \
  --command-config /etc/kafka/client/client.properties \
  --create --topic test-topic --partitions 2 --replication-factor 1

# 发送消息
echo "Hello SASL SCRAM" | bin/kafka-console-producer.sh \
  --bootstrap-server kafka-sasl-broker:9092 \
  --producer.config /etc/kafka/client/producer.properties \
  --topic test-topic
```

### 3. 测试消费者

```bash
# 消费消息
bin/kafka-console-consumer.sh \
  --bootstrap-server kafka-sasl-broker:9092 \
  --consumer.config /etc/kafka/client/consumer.properties \
  --topic test-topic --from-beginning
```

## 客户端配置示例

### Java 客户端配置

```properties
bootstrap.servers=kafka-sasl:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-256
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="kafka" password="Kafka@2025";
```

### Python 客户端配置 (kafka-python)

```python
from kafka import KafkaProducer, KafkaConsumer

producer = KafkaProducer(
    bootstrap_servers=['kafka-sasl:9092'],
    security_protocol='SASL_PLAINTEXT',
    sasl_mechanism='SCRAM-SHA-256',
    sasl_plain_username='kafka',
    sasl_plain_password='Kafka@2025'
)

consumer = KafkaConsumer(
    'test-topic',
    bootstrap_servers=['kafka-sasl:9092'],
    security_protocol='SASL_PLAINTEXT',
    sasl_mechanism='SCRAM-SHA-256',
    sasl_plain_username='kafka',
    sasl_plain_password='Kafka@2025',
    group_id='test-group'
)
```

## 安全注意事项

1. **密码管理**: 在生产环境中，建议使用 Kubernetes Secret 来管理密码，而不是直接在 values.yaml 中明文存储。

2. **网络安全**: 当前配置使用 SASL_PLAINTEXT，在生产环境中建议使用 SASL_SSL 来加密网络传输。

3. **用户权限**: 可以通过 Kafka ACL 来进一步限制用户权限。

## 故障排除

### 1. 认证失败

如果遇到认证失败，检查：
- SCRAM 用户是否正确创建
- 客户端配置中的用户名和密码是否正确
- JAAS 配置是否正确挂载

### 2. 连接超时

如果连接超时，检查：
- Kafka 服务是否正常运行
- 网络连接是否正常
- 端口配置是否正确

### 3. 查看详细日志

```bash
# 查看 Kafka broker 日志
kubectl logs -l app.kubernetes.io/component=broker -f

# 查看 SCRAM 初始化 Job 日志
kubectl logs job/kafka-sasl-broker-init-scram
```

## 升级和维护

### 添加新用户

要添加新的 SCRAM 用户，可以：

1. 更新 values.yaml 中的用户列表
2. 执行 Helm 升级：

```bash
helm upgrade kafka-sasl ./charts/kafka -f examples/values-sasl-scram.yml
```

### 修改密码

修改现有用户密码：

1. 更新 values.yaml 中的密码
2. 执行 Helm 升级
3. SCRAM 初始化 Job 会自动更新用户凭据

## 参考资料

- [Apache Kafka SASL/SCRAM 文档](https://kafka.apache.org/documentation/#security_sasl_scram)
- [Kafka 安全配置最佳实践](https://kafka.apache.org/documentation/#security)