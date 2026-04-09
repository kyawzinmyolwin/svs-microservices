#!/bin/bash

NAMESPACE="vault"
POD="vault-0"

echo "Attempting to initialize Vault on $POD..."

# 1. Run init and capture raw output. 
# We use -n instead of -it for better script compatibility.
INIT_RAW=$(kubectl exec -n $NAMESPACE $POD -- vault operator init -format=table)

if [ $? -ne 0 ]; then
    echo "FAILED: Vault might already be initialized or the pod is unreachable."
    exit 1
fi

echo "Initialization successful. Extracting keys..."

# 2. Extract keys using grep and awk
# We use 'tail -1' to ensure we only get the actual hex key string
KEY1=$(echo "$INIT_RAW" | grep "Unseal Key 1:" | awk '{print $NF}')
KEY2=$(echo "$INIT_RAW" | grep "Unseal Key 2:" | awk '{print $NF}')
KEY3=$(echo "$INIT_RAW" | grep "Unseal Key 3:" | awk '{print $NF}')
ROOT_TOKEN=$(echo "$INIT_RAW" | grep "Initial Root Token:" | awk '{print $NF}')

# Verify we actually got keys before proceeding
if [ -z "$KEY1" ]; then
    echo "ERROR: Could not parse unseal keys. Is the output format correct?"
    exit 1
fi

echo "Keys captured. Proceeding to unseal..."

# 3. Execute unseal 3 times (Threshold 3/5)
kubectl exec -n $NAMESPACE $POD -- vault operator unseal "$KEY1"
kubectl exec -n $NAMESPACE $POD -- vault operator unseal "$KEY2"
kubectl exec -n $NAMESPACE $POD -- vault operator unseal "$KEY3"

echo "--------------------------------------------------"
echo "STATUS: Vault should now be unsealed and 'Ready'."
echo "Initial Root Token: $ROOT_TOKEN"
echo "--------------------------------------------------"
echo "CRITICAL: Save these keys! They will not be shown again."
echo "$INIT_RAW" > cluster_init_output.txt
echo "Full output saved to: cluster_init_output.txt"