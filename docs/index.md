# Welcome

[![CI](https://github.com/itboon/kafka-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/itboon/kafka-docker/actions/workflows/docker-publish.yml)
[![Docker pulls](https://img.shields.io/docker/pulls/kafkace/kafka)](https://hub.docker.com/r/kafkace/kafka)
[![Docker TAG](https://img.shields.io/github/v/release/sir5kong/kafka-docker
)](https://hub.docker.com/r/kafkace/kafka/tags)
![Docker Iamge](https://img.shields.io/docker/image-size/kafkace/kafka)

- [Dockerfile](https://github.com/itboon/kafka-docker/blob/main/Dockerfile)
- [GitHub](https://github.com/itboon/kafka-docker)
- [Docker Hub](https://hub.docker.com/r/kafkace/kafka)

## 关于 Apache Kafka

[Apache Kafka](https://kafka.apache.org/) 是一个开源分布式事件流平台，已被数千家公司用于高性能数据管道、流分析、数据集成和关键任务应用程序。

> 超过 80% 的财富 100 强公司信任并使用 Kafka。

## 为何选择这个镜像

- 全面兼容 `KRaft`, 不依赖 ZooKeeper
- 灵活使用环境变量进行配置覆盖
- 上手简单
- 提供 `helm chart`，你可以在 Kubernetes 快速部署高可用 Kafka 集群
