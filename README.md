# SVS Microservices

A production-style reference project that demonstrates how to run a Flask-based microservices system on Kubernetes with independent databases, internal service discovery, and ingress routing.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Repository Layout](#repository-layout)
- [Core Features](#core-features)
- [Prerequisites](#prerequisites)
- [Quick Start (Docker Compose)](#quick-start-docker-compose)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Build, Tag, and Push Images to a Local Registry](#build-tag-and-push-images-to-a-local-registry)
- [Configure `containerd` for an Insecure Local Registry (Kind Worker)](#configure-containerd-for-an-insecure-local-registry-kind-worker)
- [Kong Ingress Setup](#kong-ingress-setup)
- [Local Host Mapping](#local-host-mapping)
- [Troubleshooting](#troubleshooting)
- [Commit Message Convention](#commit-message-convention)

## Overview
This repository showcases a multi-service application pattern with:
- A Flask frontend
- Multiple Flask backend services
- Database-per-service isolation
- Kubernetes manifests for deployments, services, ingress, and config

It is intended for local development, Kubernetes learning, and debugging real-world microservice communication flows.

## Architecture
### High-level flow
`Frontend -> Backend Service(s) -> Database`

### Platform components
- **Application layer:** Flask services
- **Data layer:** service-specific databases
- **Orchestration:** Kubernetes
- **Ingress/API gateway:** Kong (optional setup)

## Repository Layout
```text
.
├── app-services/
│   ├── appointments_service/
│   ├── catalog_service/
│   ├── customer_service/
│   ├── frontend_service/
│   └── db/
├── k8s/
│   ├── configmaps/
│   ├── deployments/
│   ├── ingress/
│   ├── logging/
│   ├── sa/
│   ├── secrets/
│   └── services/
├── kind-setup/
├── troubleshooting/
└── docker-compose.yml
```

## Core Features
- Kubernetes Deployments and Services
- Internal DNS-based service discovery
- Service-to-service REST communication
- Namespace-based environment isolation
- Practical troubleshooting and local-cluster workflows

## Prerequisites
Install the following tools before starting:
- Docker
- Kubernetes CLI (`kubectl`)
- Kind (for local Kubernetes cluster)
- Helm (for Kong installation)

## Quick Start (Docker Compose)
From the repository root:

```bash
docker compose up --build
```

Use this path for quick local development when Kubernetes is not required.

## Kubernetes Deployment
Apply Kubernetes manifests from the repository root:

```bash
kubectl apply -f k8s/
```

If needed, create namespace first (or ensure your manifests already include namespace metadata):

```bash
kubectl create ns svs-microservices
```

Apply deployments explicitly:

```bash
kubectl apply -f k8s/deployments/
```

## Build, Tag, and Push Images to a Local Registry
Start a local registry:

```bash
docker run -d -p 5000:5000 --restart=always --name local-registry registry:2
```

Example build commands:

```bash
# customer service
cd app-services/customer_service && docker build -t customer_service .

# frontend service
cd ../frontend_service && docker build -t frontend_service .

# appointments service
cd ../appointments_service && docker build -t appointment_service .
```

Tag and push example:

```bash
docker tag frontend_service localhost:5000/frontend_service:latest
docker push localhost:5000/frontend_service:latest
```

Verify registry catalog:

```bash
curl http://localhost:5000/v2/_catalog
```

## Configure `containerd` for an Insecure Local Registry (Kind Worker)
Target registry in this guide: `192.168.56.90:5000`

> **Warning**
> This setup uses insecure HTTP/skip-verify and is appropriate only for local development environments.

### Option 1: Mirror and TLS override in `config.toml`
1. Enter the worker container:
   ```bash
   docker exec -it 127-worker /bin/bash
   ```
2. Create certs directory:
   ```bash
   mkdir -p /etc/containerd/certs.d/192.168.56.90:5000
   ```
3. Append to `/etc/containerd/config.toml`:
   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.56.90:5000"]
     endpoint = ["http://192.168.56.90:5000"]

   [plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.56.90:5000".tls]
     insecure_skip_verify = true
   ```
4. Restart containerd:
   ```bash
   systemctl restart containerd
   ```

### Option 2: Host-level config with `hosts.toml`
1. Enter worker container:
   ```bash
   docker exec -it 127-worker /bin/bash
   ```
2. Create `/etc/containerd/certs.d/192.168.56.90:5000/hosts.toml`:
   ```toml
   server = "http://192.168.56.90:5000"

   [host."http://192.168.56.90:5000"]
     capabilities = ["pull", "resolve"]
     skip_verify = true
   ```
3. Ensure `/etc/containerd/config.toml` contains:
   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry]
     config_path = "/etc/containerd/certs.d"
   ```
4. Restart containerd:
   ```bash
   systemctl restart containerd
   ```

## Kong Ingress Setup
Add the Helm chart repository and install Kong:

```bash
helm repo add kong https://charts.konghq.com
helm repo update

helm install kong kong/kong \
  --namespace kong \
  --create-namespace \
  --set ingressController.enabled=true \
  --set ingressController.installCRDs=false \
  --set proxy.type=NodePort \
  --set proxy.http.nodePort=30317 \
  --set proxy.tls.nodePort=32443 \
  --set admin.enabled=true \
  --set admin.type=NodePort \
  --set admin.http.nodePort=32081 \
  --set admin.http.enabled=true
```

Apply ingress:

```bash
kubectl apply -f k8s/ingress/kong-ingress.yaml -n svs-microservices
```

## Local Host Mapping
Map your local hostname to the cluster host IP:

```bash
sudo vi /etc/hosts
```

Add:

```text
192.168.56.90 svs-app.local
```

Access:

```text
http://svs-app.local:8080/
```

## Troubleshooting
See project notes in:
- `troubleshooting/service-url-issue.md`
- service-level notes under `app-services/*/`

## Commit Message Convention
Use Conventional Commit-style prefixes:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation updates
- `refactor:` for code structure changes without behavior changes

Examples:
- `feat: add appointment service CRUD endpoints`
- `fix: resolve environment variable misconfiguration`
- `docs: add troubleshooting guide`
- `refactor: split DB access into connector`
