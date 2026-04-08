#!/bin/bash

# Create the Helm chart directory structure
mkdir -p svs-microservices-chart/templates/{deployments,ingresses}

# Copy all the above files into the appropriate directories

# Install the Helm chart
helm install svs-microservices ./svs-microservices-chart \
  --namespace svs-microservices \
  --create-namespace \
  --set frontend.image.tag=latest \
  --set customer.image.tag=latest \
  --set appointment.image.tag=latest

# Upgrade the Helm chart (when making changes)
helm upgrade svs-microservices ./svs-microservices-chart \
  --namespace svs-microservices

# Uninstall
# helm uninstall svs-microservices --namespace svs-microservices