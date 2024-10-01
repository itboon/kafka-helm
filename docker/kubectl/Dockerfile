FROM debian:12

ARG app_version=1.30

RUN set -ex \
  ; apt-get update \
  ; apt-get install apt-transport-https ca-certificates curl gnupg -y --no-install-recommends \
  ; rm -rf /var/lib/apt/lists/*

  RUN set -ex \
  ; curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${app_version}/deb/Release.key" \
    | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
  ; chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
  ; echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${app_version}/deb/ /" \
    | tee /etc/apt/sources.list.d/kubernetes.list \
  ; chmod 644 /etc/apt/sources.list.d/kubernetes.list \
  ; apt-get update \
  ; apt-get install kubectl -y --no-install-recommends \
  ; rm -rf /var/lib/apt/lists/*
