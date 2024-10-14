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
| broker.external.type | string | `NodePort` | `NodePort` `LoadBalancer` `HostPort` or `PodIP` |
| broker.external.service.annotations | object | `{}` | External serivce annotations, 可用于配置 `LoadBalancer` |
| broker.external.autoDiscovery.enabled | bool | `false` | 用于自动发现 `NodePort` 端口号和 `LoadBalancer` 地址 |
| broker.external.externalDns.enabled | bool | `false` | 开启 [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) 为外部访问地址添加公共域名解析 |
| broker.external.externalDns.domain | string | `""` | ExternalDNS 管理的域名 |
| broker.external.externalDns.hostnamePrefix | string | `""` | `<releaseName>-<Namespace>` |
| broker.external.externalDns.annotations | object | `{}` | ExternalDNS service annotations |

### values 案例

``` yaml
## NodePort example
broker:
  external:
    enabled: true
    service:
      type: "NodePort"
      annotations: {}
    autoDiscovery:
      enabled: true
```

``` yaml
## LoadBalancer example
broker:
  external:
    enabled: true
    service:
      type: "LoadBalancer"
      annotations: {}
    autoDiscovery:
      enabled: true
```

### ExternalDNS 案例

ExternalDNS 需要另行部署，参考文档:

- [Setting up ExternalDNS for Services on AWS]<https://kubernetes-sigs.github.io/external-dns/latest/docs/tutorials/aws/>

假如 `my-external-dns.example.com` 是 ExternalDNS 管理的域名， Helm Release 是 `kafka`，以下分别是 NodePort 和 LoadBalancer 部署案例:

``` yaml
## ExternalDNS with NodePort
broker:
  external:
    enabled: true
    service:
      type: "NodePort"
      annotations: {}
    externalDns:
      enabled: true
      domain: "my-external-dns.example.com"
      annotations: {}

## broker 外部地址: kafka-broker-0.kafka-dev.my-external-dns.example.com
```

> LoadBalancer ExternalDNS 作用在 external service，其他类型 ExternalDNS 作用在 headless service， 所以用法有差异。

``` yaml
## ExternalDNS with LoadBalancer
broker:
  external:
    enabled: true
    service:
      type: "LoadBalancer"
      annotations: {}
    externalDns:
      enabled: true
      domain: "my-external-dns.example.com"
      annotations: {}

## broker 外部地址: kafka-broker-0.my-external-dns.example.com
```

#### hostnamePrefix

``` yaml
broker:
  external:
    enabled: true
    service:
      type: "LoadBalancer"
      annotations: {}
    externalDns:
      enabled: true
      domain: "my-external-dns.example.com"
      hostnamePrefix: "kafka-foo"
      annotations: {}

## broker 外部地址: kafka-foo-0.my-external-dns.example.com
```

``` yaml
broker:
  external:
    enabled: true
    service:
      type: "NodePort"
      annotations: {}
    externalDns:
      enabled: true
      domain: "my-external-dns.example.com"
      hostnamePrefix: "kafka-foo"
      annotations: {}

## broker 外部地址: kafka-broker-0.kafka-foo.my-external-dns.example.com
```