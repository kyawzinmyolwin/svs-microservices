# Get the value
# export ECR_URL=$(terraform output -raw ecr_registry_url)
# export DB_HOST=$(terraform output -raw rds_endpoint)

# Update the YAML file in-place
yq -i ".registry = \"$(terraform output -raw ecr_registry_url)\"" kind-values.yaml
yq -i ".dbHost = \"$(terraform output -raw db_host)\"" kind-values.yaml