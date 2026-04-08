#!/bin/bash
# fix-and-install.sh

# Create the values file with all required fields
cat > kind-values.yaml << 'EOF'
namespace: svs-microservices
registry: 192.168.56.90:5000
imagePullPolicy: Always
dbHost: "192.168.56.1"

serviceAccounts:
  customers: svs-app-customers-sa
  catalog: svs-app-catalog-sa
  appointments: svs-app-appointments-sa

frontend:
  enabled: true
  replicas: 2
  image:
    repository: frontend_service
    tag: latest
  service:
    port: 80
    targetPort: 5000
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "250m"
      memory: "256Mi"
  config:
    customerSvcUrl: "http://svs-service-customer:5002"
    catalogSvcUrl: "http://svs-service-catalog:5001"
    appointmentsSvcUrl: "http://svs-service-appointment:5003"
  secrets:
    flaskSecretKey: "dev-secret-key"

customer:
  enabled: true
  replicas: 2
  image:
    repository: customer_service
    tag: latest
  service:
    port: 5002
    targetPort: 5002
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "250m"
      memory: "256Mi"
  config:
    dbHost: "192.168.56.1"
  vault:
    enabled: false
  secrets:
    dbUser: "customers_user"
    dbPass: "CustomersP@ss"

catalog:
  enabled: true
  replicas: 2
  image:
    repository: catalog_service
    tag: latest
  service:
    port: 5001
    targetPort: 5001
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "250m"
      memory: "256Mi"
  config:
    dbHost: "192.168.56.1"
  vault:
    enabled: false
  secrets:
    dbUser: "catalog_user"
    dbPass: "CatalogP@ss"

appointment:
  enabled: true
  replicas: 2
  image:
    repository: appointment_service
    tag: latest
  service:
    port: 5003
    targetPort: 5003
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "250m"
      memory: "256Mi"
  config:
    dbHost: "192.168.56.1"
  vault:
    enabled: false
  secrets:
    dbUser: "appointments_user"
    dbPass: "NewSecureP@ss2026"

ingress:
  kong:
    enabled: true
    className: kong
    host: svs-app.local
    plugins:
      rateLimiting:
        enabled: true
        minute: 100
        policy: local
      requestSizeLimiting:
        enabled: true
        allowedPayloadSize: 8
    paths:
      frontend: /
      customer: /api/customers
      catalog: /api/catalog
      appointment: /api/appointments
  nginx:
    enabled: false
EOF

# Now run the lint
helm lint ./svs-microservices-chart --values kind-values.yaml

# If lint passes, install
if [ $? -eq 0 ]; then
  echo "✅ Lint passed! Installing..."
  helm install svs-microservices ./svs-microservices-chart \
    --namespace svs-microservices \
    --create-namespace \
    --values kind-values.yaml \
    --dry-run --debug
else
  echo "❌ Lint failed. Please check the errors."
fi