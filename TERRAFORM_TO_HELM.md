# Terraform Outputs to Helm Values Integration

This document explains how to automatically populate Helm values with Terraform outputs for `DB_HOST` and Docker image URLs.

## Problem

Previously, `DB_HOST` and Docker image URLs had to be manually updated in `svs-helm-eks/values.yaml`:
- `DB_HOST`: The RDS database endpoint (was hardcoded as `192.168.56.1`)
- Image URLs: ECR registry URLs (were hardcoded or referenced local registries)

This required manual intervention after Terraform deployment and was error-prone.

## Solution

Two scripts have been created to automate this process:

### 1. `scripts/ecr-update-url.sh` (Simple)

**Use case:** Quick update of both Kind and EKS values files

```bash
cd /path/to/svs-microservices
./scripts/ecr-update-url.sh
```

This script:
- Extracts `ecr_registry_url` and `rds_endpoint` from Terraform outputs
- Updates `kind-values.yaml` with ECR registry URL and DB host
- Updates `svs-helm-eks/values.yaml` with ECR registry URL and DB host for all services
- Simple error handling with `set -euo pipefail`

**Requirements:**
- Must be run from the project root directory
- Terraform state must exist locally (already applied infrastructure)
- `yq` CLI tool must be installed
- `terraform` CLI must be in PATH

### 2. `scripts/update-helm-from-terraform.sh` (Advanced)

**Use case:** Detailed control and visibility into what's being updated

```bash
# Dry run to see what would be changed
./scripts/update-helm-from-terraform.sh --dry-run

# Actually apply the updates
./scripts/update-helm-from-terraform.sh
```

This script:
- Validates all prerequisites (terraform, yq, Terraform state)
- Extracts both base registry URL and individual service image URLs from ECR
- Shows what values will be updated before applying changes
- Supports dry-run mode to preview changes without modifying files
- Provides helpful error messages and next steps
- Handles both global and service-specific configurations

**Features:**
- ✓ Validates Terraform state exists
- ✓ Error handling with clear messages
- ✓ Dry-run mode for safety
- ✓ Updates individual service database hosts
- ✓ Handles service-specific ECR repository URLs
- ✓ Color-coded output for better readability

## What Gets Updated

### In `svs-helm-eks/values.yaml`:

```yaml
# Global settings
registry: <ECR_REGISTRY_URL>  # From: terraform output ecr_registry_url
dbHost: <RDS_ENDPOINT>        # From: terraform output rds_endpoint

# Customer service
customer:
  config:
    dbHost: <RDS_ENDPOINT>
  image:
    repository: customer_service  # Will be prefixed with registry in template

# Catalog service  
catalog:
  config:
    dbHost: <RDS_ENDPOINT>
  image:
    repository: catalog_service   # Will be prefixed with registry in template

# Appointment service
appointment:
  config:
    dbHost: <RDS_ENDPOINT>
  image:
    repository: appointment_service

# Frontend service
frontend:
  image:
    repository: frontend_service
```

### Template Usage

Templates now consistently use:
```yaml
image: {{ .Values.registry }}/{{ .Values.<service>.image.repository }}:{{ .Values.<service>.image.tag }}
```

This applies to:
- `svs-helm-eks/templates/customer.yaml`
- `svs-helm-eks/templates/catalog.yaml`
- `svs-helm-eks/templates/appointment.yaml`
- `svs-helm-eks/templates/frontend.yaml`

## Terraform Outputs Referenced

The scripts extract values from these Terraform outputs:

```hcl
# From terraform/modules/rds/outputs.tf
output "rds_endpoint" {
  description = "RDS endpoint — replaces 192.168.56.1 in your ConfigMaps"
  value       = module.rds.endpoint
}

# From terraform/modules/ecr/outputs.tf
output "ecr_registry_url" {
  description = "Base ECR registry URL — use for docker login"
  value       = module.ecr.registry_url
}

output "ecr_repository_urls" {
  description = "Map of service name to ECR URL"
  value       = module.ecr.repository_urls
}
```

## Usage Workflow

### Step 1: Deploy Terraform Infrastructure

```bash
cd terraform
terraform plan
terraform apply
```

### Step 2: Update Helm Values

Option A - Quick update:
```bash
./scripts/ecr-update-url.sh
```

Option B - With verification:
```bash
./scripts/update-helm-from-terraform.sh --dry-run  # Preview changes
./scripts/update-helm-from-terraform.sh            # Apply changes
```

### Step 3: Review Changes

```bash
git diff svs-helm-eks/values.yaml
```

### Step 4: Deploy with Helm

```bash
helm upgrade --install svs-app ./svs-helm-eks -f svs-helm-eks/values.yaml
```

## Troubleshooting

### Error: "No Terraform state found"
- **Cause:** Terraform hasn't been applied yet
- **Solution:** Run `terraform apply` in the `terraform/` directory first

### Error: "yq is required"
- **Cause:** `yq` CLI tool not installed
- **Solution:** 
  - macOS: `brew install yq`
  - Ubuntu/Debian: `apt-get install yq`
  - Other: Visit https://github.com/mikefarah/yq

### Error: "rds_endpoint not found in Terraform outputs"
- **Cause:** RDS module not deployed or variable name mismatch
- **Solution:** Check `terraform/outputs.tf` for output definitions

### Empty registry URL
- **Cause:** ECR module not deployed
- **Solution:** Ensure ECR module is included in Terraform configuration

## Configuration Changes Made

### `svs-helm-eks/values.yaml`
- Line 74: Changed `repository: 192.168.56.90:5000/catalog_service` to `repository: catalog_service`
  - Now uses registry prefix from `.Values.registry` consistently

### `svs-helm-eks/templates/catalog.yaml`
- Line 30: Updated image reference from `{{ .Values.catalog.image.repository }}` to `{{ .Values.registry }}/{{ .Values.catalog.image.repository }}`
  - Now matches pattern used by other services

### `scripts/ecr-update-url.sh`
- Converted from commented-out example to executable script
- Added support for updating both `kind-values.yaml` and `svs-helm-eks/values.yaml`
- Fixed output name from `db_host` to `rds_endpoint`
- Added service-specific dbHost updates

### New File
- `scripts/update-helm-from-terraform.sh` - Advanced automation script with validation and dry-run support

## Manual Updates (One-Time)

If you prefer to update values manually:

1. Get outputs:
   ```bash
   cd terraform
   terraform output rds_endpoint
   terraform output ecr_registry_url
   ```

2. Update `svs-helm-eks/values.yaml` with these values

## CI/CD Integration

These scripts can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Update Helm from Terraform
  working-directory: svs-microservices
  run: ./scripts/update-helm-from-terraform.sh
```

## See Also

- [Terraform Configuration](./terraform/README.md)
- [Helm Chart Documentation](./svs-helm-eks/README.md)
- [Deployment Guide](./troubleshooting/README.md)
