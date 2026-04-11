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
docker tag frontend_service 192.168.56.90:5000/frontend_service:latest
docker push 192.168.56.90:5000/frontend_service:latest
```

Verify registry catalog:

```bash
curl http://192.168.56.90:5000/v2/_catalog
```

## Configure `containerd` for an Insecure Local Registry (Kind Worker)
Target registry in this guide: `192.168.56.90:5000`

> **Warning**
> This setup uses insecure HTTP/skip-verify and is appropriate only for local development environments.

### Option 1: Mirror and TLS override in `config.toml`
1. Enter the worker container:
   ```bash
   docker exec -it 127-worker3 /bin/bash
   ```
2. Append to `/etc/containerd/config.toml`:
   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.56.90:5000"]
     endpoint = ["http://192.168.56.90:5000"]

   [plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.56.90:5000".tls]
     insecure_skip_verify = true
   ```
3. Restart containerd:
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
### Registry Script for docker local registry

- [configure_registry.sh](#svs-microservices/docker-registry/configure_registry.sh)

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

## Vault Installation & Initialisation

### Step 1 - Install Vault via Helm

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
 
kubectl create namespace vault
 
# ── DEV MODE (quick-start / portfolio demo) ──────────────────
helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --set server.dev.enabled=true \
  --set injector.enabled=true
 
# ── PRODUCTION MODE (persistent storage) ────────────────────
helm install vault hashicorp/vault \
  --namespace vault \
  --set server.ha.enabled=false \
  --set server.dataStorage.enabled=true \
  --set server.dataStorage.size=10Gi \
  --set injector.enabled=true
```
### STEP 2 — Initialise & Unseal (Production Mode only)
```
kubectl exec -n vault -it vault-0 -- vault operator init

# Save the 5 Unseal Keys and Root Token somewhere secure (e.g. 1Password)!
 
# Unseal (run 3 times with different keys)
kubectl exec -n vault -it vault-0 -- vault operator unseal <Unseal-Key-1>
kubectl exec -n vault -it vault-0 -- vault operator unseal <Unseal-Key-2>
kubectl exec -n vault -it vault-0 -- vault operator unseal <Unseal-Key-3>
 
# Verify
kubectl get pods -n vault   # STATUS should be Running
```
### STEP 3 — Login to Vault
``` 
kubectl exec -it -n vault vault-0 -- sh
```
## Kubernetes Auth Method
### STEP 4 — Enable & Configure Kubernetes Auth
```
vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```
Verify 
```
vault auth list
```
## In this repo, I use 3 different ways for database authentication between pod and Database.

- [Dynamic Secrets - MySQL](#DynamicSecrets) - For svs-customer pods
- [Static Secrets](#architecture) - For svs-appointments pods
- [ConfigMap & Secrets](#repository-layout) - For svs-catalog pods

## DynamicSecrets — MySQL

STEP 6A — Prepare MySQL Admin User
Run on your MySQL host (Vagrant host IP: 192.168.56.1):
```
mysql -u root -p

-- Create a dedicated Vault admin account (never exposed to apps)
CREATE USER 'vault_admin'@'%' IDENTIFIED BY 'VaultP@ssw0rd';
GRANT ALL PRIVILEGES ON *.* TO 'vault_admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
 
-- Create the application databases
CREATE DATABASE customers_svs;
CREATE DATABASE catalog_svs;
```


### STEP 6B — Enable Database Secrets Engine & Configure MySQL
# Inside vault-0 pod
```
vault secrets enable database
```

# Customers DB connection
```
vault write database/config/customers_svs \
  plugin_name=mysql-database-plugin \
  connection_url='{{username}}:{{password}}@tcp(192.168.56.1:3306)/' \
  allowed_roles='svs-customer-role' \
  username='vault_admin' \
  password='VaultP@ssw0rd'

#Verify
vault read database/config/customers_svs
```
### STEP 6C — Define MySQL Dynamic Roles
```
vault write database/roles/svs-customer-role \
  db_name=customers_svs \
  creation_statements="
    CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
    GRANT SELECT, INSERT, UPDATE, DELETE ON customers_svs.* TO '{{name}}'@'%';
  " \
  default_ttl="15m" \
  max_ttl="1h"

```
```
# Test credential generation immediately
```
vault read database/creds/svs-customer-role
```
# Expected: username=v-token-svs-custom-xxxx  password=<random>  lease_duration=15m
```
### STEP 6D — Write Vault Policies for Dynamic MySQL
```
cat <<EOF > /home/vault/svs-customer-db-policy.hcl
path "database/creds/svs-customer-role" {
  capabilities = ["read"]
}
EOF
vault policy write svs-customer-db-policy /home/vault/svs-customer-db-policy.hcl
```
## Kubernetes ServiceAccounts & Vault Roles
```
kubectl apply -f ~/svs-microservices/k8s/sa/serviceaccounts.yaml
```
### STEP 9 — Bind ServiceAccounts to Vault Roles
Back inside the vault-0 pod shell:
```
# Customers — dynamic MySQL
vault write auth/kubernetes/role/svs-role-customers \
  bound_service_account_names=svs-app-customers-sa \
  bound_service_account_namespaces=svs-microservices \
  policies=svs-customer-db-policy \
  ttl=1h
```
```
# Verify
vault read auth/kubernetes/role/svs-role-customers
```
## Option 2 - Vault Static Secrets (KV)

### Enable Secrets
```
vault secrets enable -path=secret kv-v2
```

### STEP 1 - Vault policy for Static MySQL
```
cat <<EOF > /home/vault/svs-catalog-db-policy.hcl
path "secret/data/svs/catalog-db" {
  capabilities = ["read"]
}
EOF
vault policy write svs-catalog-db-policy /home/vault/svs-catalog-db-policy.hcl
```
### STEP 2 — Store DB Credentials in Vault
```
vault kv put secret/svs/catalog-db \
  username="catalog_user" \
  password="CatalogP@ss"

```
Verify:
```
vault kv get secret/svs/catalog-db
```
### STEP  — Bind ServiceAccount to Vault Role
```
vault write auth/kubernetes/role/svs-role-catalog \
  bound_service_account_names=svs-app-catalog-sa \
  bound_service_account_namespaces=svs-microservices \
  policies=svs-catalog-db-policy \
  ttl=1h
```