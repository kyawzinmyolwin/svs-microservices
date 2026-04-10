#!/bin/bash
#
# Update svs-helm-eks values with Terraform outputs
# This script automatically populates DB_HOST and ECR image URLs from Terraform state
#
# Usage: ./scripts/update-helm-from-terraform.sh [--dry-run]
#

set -euo pipefail

DRY_RUN=${1:-}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
HELM_VALUES="$PROJECT_ROOT/svs-helm-eks/values.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
  echo -e "${RED}Error: $*${NC}" >&2
  exit 1
}

success() {
  echo -e "${GREEN}✓ $*${NC}"
}

info() {
  echo -e "${YELLOW}→ $*${NC}"
}

# Check if yq is installed
if ! command -v yq &> /dev/null; then
  error "yq is required. Please install it: brew install yq (macOS) or apt-get install yq (Linux)"
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
  error "terraform is required. Please install it."
fi

# Check if we're in a git repo
if [[ ! -d "$TERRAFORM_DIR" ]]; then
  error "Terraform directory not found at $TERRAFORM_DIR"
fi

if [[ ! -f "$HELM_VALUES" ]]; then
  error "Helm values file not found at $HELM_VALUES"
fi

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Check if terraform has any state
if ! terraform state list &>/dev/null || [[ -z "$(terraform state list 2>/dev/null || true)" ]]; then
  error "No Terraform state found. Please run 'terraform apply' first."
fi

info "Fetching Terraform outputs..."

# Extract values from Terraform outputs
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "")
ECR_REGISTRY_URL=$(terraform output -raw ecr_registry_url 2>/dev/null || echo "")
ECR_REPO_URLS=$(terraform output -json ecr_repository_urls 2>/dev/null || echo '{}')

# Validate we have the required outputs
if [[ -z "$RDS_ENDPOINT" ]]; then
  error "Could not retrieve rds_endpoint from Terraform outputs"
fi

if [[ -z "$ECR_REGISTRY_URL" ]]; then
  error "Could not retrieve ecr_registry_url from Terraform outputs"
fi

info "Retrieved values:"
info "  RDS Endpoint: $RDS_ENDPOINT"
info "  ECR Registry URL: $ECR_REGISTRY_URL"

# Extract individual service image URLs from ECR repository URLs
FRONTEND_IMAGE=$(echo "$ECR_REPO_URLS" | jq -r '.frontend_service // empty' 2>/dev/null || echo "")
CUSTOMER_IMAGE=$(echo "$ECR_REPO_URLS" | jq -r '.customer_service // empty' 2>/dev/null || echo "")
CATALOG_IMAGE=$(echo "$ECR_REPO_URLS" | jq -r '.catalog_service // empty' 2>/dev/null || echo "")
APPOINTMENT_IMAGE=$(echo "$ECR_REPO_URLS" | jq -r '.appointment_service // empty' 2>/dev/null || echo "")

# If individual service images are available, use them; otherwise use registry URL + service name
if [[ -z "$CUSTOMER_IMAGE" ]]; then
  CUSTOMER_IMAGE="$ECR_REGISTRY_URL/customer_service"
fi
if [[ -z "$CATALOG_IMAGE" ]]; then
  CATALOG_IMAGE="$ECR_REGISTRY_URL/catalog_service"
fi
if [[ -z "$APPOINTMENT_IMAGE" ]]; then
  APPOINTMENT_IMAGE="$ECR_REGISTRY_URL/appointment_service"
fi
if [[ -z "$FRONTEND_IMAGE" ]]; then
  FRONTEND_IMAGE="$ECR_REGISTRY_URL/frontend_service"
fi

info "Extracted service images:"
info "  Frontend: $FRONTEND_IMAGE"
info "  Customer: $CUSTOMER_IMAGE"
info "  Catalog: $CATALOG_IMAGE"
info "  Appointment: $APPOINTMENT_IMAGE"

if [[ "$DRY_RUN" == "--dry-run" ]]; then
  info "DRY RUN MODE - no changes will be made"
  echo ""
  echo "Would update: $HELM_VALUES"
  echo ""
  echo "Changes that would be applied:"
  echo "  .dbHost = \"$RDS_ENDPOINT\""
  echo "  .registry = \"$ECR_REGISTRY_URL\""
  echo "  .frontend.image.repository = \"$FRONTEND_IMAGE\""
  echo "  .customer.image.repository = \"$CUSTOMER_IMAGE\""
  echo "  .catalog.image.repository = \"$CATALOG_IMAGE\""
  echo "  .appointment.image.repository = \"$APPOINTMENT_IMAGE\""
  echo ""
  echo "Also updating individual service dbHost values:"
  echo "  .customer.config.dbHost = \"$RDS_ENDPOINT\""
  echo "  .catalog.config.dbHost = \"$RDS_ENDPOINT\""
  echo "  .appointment.config.dbHost = \"$RDS_ENDPOINT\""
  exit 0
fi

# Update the Helm values file
info "Updating Helm values file: $HELM_VALUES"

cd "$PROJECT_ROOT"

# Update registry and dbHost at global level
yq -i ".registry = \"$ECR_REGISTRY_URL\"" "$HELM_VALUES"
yq -i ".dbHost = \"$RDS_ENDPOINT\"" "$HELM_VALUES"

# Update service-specific database hosts
yq -i ".customer.config.dbHost = \"$RDS_ENDPOINT\"" "$HELM_VALUES"
yq -i ".catalog.config.dbHost = \"$RDS_ENDPOINT\"" "$HELM_VALUES"
yq -i ".appointment.config.dbHost = \"$RDS_ENDPOINT\"" "$HELM_VALUES"

# Update service image repositories
yq -i ".frontend.image.repository = \"$FRONTEND_IMAGE\"" "$HELM_VALUES"
yq -i ".customer.image.repository = \"$CUSTOMER_IMAGE\"" "$HELM_VALUES"
yq -i ".catalog.image.repository = \"$CATALOG_IMAGE\"" "$HELM_VALUES"
yq -i ".appointment.image.repository = \"$APPOINTMENT_IMAGE\"" "$HELM_VALUES"

success "Updated Helm values with Terraform outputs"
success "DB_HOST: $RDS_ENDPOINT"
success "ECR Registry: $ECR_REGISTRY_URL"
success "Service images updated"

echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff $HELM_VALUES"
echo "  2. Deploy with Helm: helm upgrade --install svs-app ./svs-helm-eks -f $HELM_VALUES"
