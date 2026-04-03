# SVS Microservices

A Flask-based microservices application demonstrating:
- Service-to-service communication
- Docker & Docker Compose
- Database-per-service
- CI/CD with GitHub Actions

This project demonstrates service-to-service communication in Kubernetes using
a Flask-based frontend and backend with a database.

## 🧱 Architecture
- Frontend: Flask application
- Backend: Flask REST API
- Database: MySQL/PostgreSQL
- Platform: Kubernetes

## 🔁 Service Communication Flow
Frontend → Backend Service → Database Service

## 🚀 Features
- Kubernetes Deployments & Services
- Internal DNS-based service discovery
- REST API communication
- Real-world troubleshooting scenarios
- Add Github Runner for local pipeline testing...

## 📦 Kubernetes Resources
- Deployments
- ClusterIP Services
- ConfigMaps
- Namespaces

## 🛠 How to Deploy

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
```
## Message Styles
feat: add appointment service CRUD endpoints
fix: resolve env variable misconfiguration
docs: add troubleshooting guide
refactor: split db access into connector

## Kind Cluster Setup
```bash
cd svs-microservices/kind-setup/
./setup-kindcluster127-port-mapping.sh
```
## Service Port map to Kind Cluster

# Containerd Registry Configuration Guide

This documentation outlines the steps to configure a custom insecure registry for `containerd` within a Docker worker node. This process ensures that the node can pull images from a private registry located at `192.168.56.90:5000`.

---

## Prerequisites
* Access to the host machine running Docker.
* A running container named `127-worker`.
* Root or sudo privileges within the container.

## Docker Build

### Customer Service
#### svs-microservices/app-services/catalog_service
```
docker build -t customer_service .

```

### Frontend Service
#### svs-microservices/app-services/frontend_service
```
docker build -t frontend_service .

```

### Appointment Service
#### svs-microservices/app-services/appointments_service
```
docker build -t appointment_service .
```
#### Run the official Docker Registry Container and map the port.
```
docker run -d -p 5000:5000 --restart=always --name local-registry registry:2
```
#### Verify the Local Registry
```
curl http://localhost:5000/v2/_catalog
```
### Docker Tag


```
docker tag frontend_service localhost:5000/frontend_service:latest
```


#### Docker Push to Registry
```
docker push localhost:5000/frontend_service:latest
```

#### http: server gave HTTP response to HTTPS client
```
vi cat /etc/docker/daemon.json

Add this block
 {
	"insecure-registries":["192.168.56.90:5000"],
	"experimental" : false
}
```
#### Verify image name in Deployment YAML

### Configure Trust Relation to containerd
#### I tested two different approach for this configuration.


---

## Step-by-Step Configuration

### 1. Access the Worker Container
Enter the interactive shell of the worker container to perform administrative tasks.
```bash
docker exec -it 127-worker /bin/bash
```

### 2. Create the Certificate Directory
Create a specific directory path for the registry host. This structure is used by `containerd` to discover custom configurations for specific endpoints.
```bash
mkdir -p /etc/containerd/certs.d/192.168.56.90:5000
```

### 3. Install Text Editor
Update the package lists and install `vim` to allow for file editing within the container environment.
```bash
apt-get update && apt-get install -y vim
```

### 4. Update Global Containerd Configuration
Modify the primary `containerd` configuration file to define the registry mirror and TLS settings.

* **File:** `/etc/containerd/config.toml`
* **Action:** Append the following block to the end of the file:

```toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.56.90:5000"]
  endpoint = ["http://192.168.56.90:5000"]

[plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.56.90:5000".tls]
  insecure_skip_verify = true
```

### 5. Restart the Service
Apply the changes by restarting the `containerd` daemon.
```bash
systemctl restart containerd
```

---

> **Note:** Since this configuration uses `insecure_skip_verify = true` and `http`, it is intended for **development or internal lab environments**. Ensure proper security measures are in place before using similar configurations in production.

## Option-2

### 1. Access the Worker Container
Enter the interactive shell of the worker container to perform administrative tasks.
```bash
docker exec -it 127-worker /bin/bash
```

### 1. Configure Host-Specific Discovery
Create a `hosts.toml` file within the certificate directory created in Step 2. This explicitly defines how `containerd` should interact with this specific server.

* **File:** `/etc/containerd/certs.d/192.168.56.90:5000/host.toml`
* **Content:**
```toml
server = "http://192.168.56.90:5000"

[host."http://192.168.56.90:5000"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
```
### 2. Update Global Containerd Configuration
Modify the primary `containerd` configuration file to define the registry mirror and TLS settings.

* **File:** `/etc/containerd/config.toml`
* **Action:** Append the following block to the end of the file:

```toml
[plugins."io.containerd.grpc.v1.cri".registry]
  config_path = "/etc/containerd/certs.d"
`
```
### 3. Restart the Service
Apply the changes by restarting the `containerd` daemon.
```bash
systemctl restart containerd
```

### Create Namespace
``` 
kubectl create ns svs-microservices 
```

#### Run the Deployment YAML
``` 
kubectl apply -f svs-microservices/k8s/deployments/
```
### Kong Setup
```
helm repo add kong https://charts.konghq.com
helm repo update
```
```
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
### Apply Ingress Config
``` 
kubectl apply -f ~/svs-microservices/k8s/ingress/kong-ingress.yaml -n svs-microservices
```
### Access your kubernetes app from host machine
``` 
sudo vi /etc/hosts
```
```
192.168.56.90   svs-app.local
```
#### Accessing from Host Browser
```
http://svs-app.local:8080/
```

