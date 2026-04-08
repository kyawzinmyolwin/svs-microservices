#!/bin/bash

# List of worker nodes
WORKERS=("127-worker" "127-worker2" "127-worker3")

# Registry configuration
REGISTRY_HOST="192.168.56.90:5000"
CONFIG_DIR="/etc/containerd/certs.d/${REGISTRY_HOST}"

# Function to configure a single worker
configure_worker() {
    local worker=$1
    
    echo "========================================="
    echo "Configuring $worker..."
    echo "========================================="
    
    # Create the certs.d directory and hosts.toml file
    docker exec $worker bash -c "mkdir -p $CONFIG_DIR"
    
    # Write the hosts.toml configuration
    docker exec $worker bash -c "cat > $CONFIG_DIR/hosts.toml << 'EOF'
server = \"http://${REGISTRY_HOST}\"

[host.\"http://${REGISTRY_HOST}\"]
  capabilities = [\"pull\", \"resolve\"]
  skip_verify = true
EOF"
    
    # Check if config_path already exists in config.toml
    if ! docker exec $worker grep -q "config_path = \"/etc/containerd/certs.d\"" /etc/containerd/config.toml 2>/dev/null; then
        echo "Adding registry config_path to config.toml..."
        # Backup original config
        docker exec $worker cp /etc/containerd/config.toml /etc/containerd/config.toml.bak.$(date +%Y%m%d_%H%M%S)
        
        # Add registry configuration (if section exists, add line; if not, create section)
        docker exec $worker bash -c "cat >> /etc/containerd/config.toml << 'EOF'

[plugins.\"io.containerd.grpc.v1.cri\".registry]
  config_path = \"/etc/containerd/certs.d\"
EOF"
    else
        echo "registry config_path already exists in config.toml"
    fi
    
    # Restart containerd
    echo "Restarting containerd on $worker..."
    docker exec $worker systemctl restart containerd
    
    # Check status
    sleep 2
    if docker exec $worker systemctl is-active containerd > /dev/null 2>&1; then
        echo "✅ $worker configured successfully"
    else
        echo "❌ $worker containerd failed to restart"
    fi
    echo ""
}

# Main execution
echo "Starting containerd registry configuration for all workers..."
echo "Registry: $REGISTRY_HOST"
echo ""

# Configure each worker
for worker in "${WORKERS[@]}"; do
    # Check if worker container is running
    if docker ps --format '{{.Names}}' | grep -q "^${worker}$"; then
        configure_worker $worker
    else
        echo "⚠️  Warning: $worker container is not running, skipping..."
        echo ""
    fi
done

echo "========================================="
echo "Configuration complete!"
echo "========================================="