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
- Add Github Runner for local pipeline testing.

## 📦 Kubernetes Resources
- Deployments
- ClusterIP Services
- ConfigMaps
- Namespaces

## 🛠 How to Deploy

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/

## Message Styles
feat: add appointment service CRUD endpoints
fix: resolve env variable misconfiguration
docs: add troubleshooting guide
refactor: split db access into connector

