#!/bin/bash
# Update ECR URL and DB_HOST from Terraform outputs
# This script updates both kind-values.yaml and svs-helm-eks values.yaml

set -euo pipefail

# Get the Terraform outputs
ECR_URL=$(terraform output -raw ecr_registry_url)
DB_HOST=$(terraform output -raw rds_endpoint)

echo "Updating values with:"
echo "  ECR_URL: $ECR_URL"
echo "  DB_HOST: $DB_HOST"

# Update kind-values.yaml (for local Kind cluster testing)
if [[ -f "kind-values.yaml" ]]; then
  yq -i ".registry = \"$ECR_URL\"" kind-values.yaml
  yq -i ".dbHost = \"$DB_HOST\"" kind-values.yaml
  echo "✓ Updated kind-values.yaml"
fi

# Update svs-helm-eks values.yaml (for EKS deployment)
if [[ -f "svs-helm-eks/values.yaml" ]]; then
  yq -i ".registry = \"$ECR_URL\"" svs-helm-eks/values.yaml
  yq -i ".dbHost = \"$DB_HOST\"" svs-helm-eks/values.yaml
  yq -i ".customer.config.dbHost = \"$DB_HOST\"" svs-helm-eks/values.yaml
  yq -i ".catalog.config.dbHost = \"$DB_HOST\"" svs-helm-eks/values.yaml
  yq -i ".appointment.config.dbHost = \"$DB_HOST\"" svs-helm-eks/values.yaml
  echo "✓ Updated svs-helm-eks/values.yaml"
fi

echo "✓ Done!"