#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# bootstrap.sh — Phase 1: Vault init/unseal
# Run ONCE after helm install vault, BEFORE terraform apply.
# ──────────────────────────────────────────────────────────────────
set -euo pipefail

VAULT_NAMESPACE="vault"
VAULT_POD="vault-0"
KEYS_FILE="./vault-keys.json"

# ── Helper: parse JSON without assuming jq is installed ───────────
# Always outputs lowercase true/false regardless of tool used
parse_json() {
  local json="$1"
  local key="$2"
  if command -v jq &>/dev/null; then
    echo "${json}" | jq -r "${key}"
  else
    # python3: force lowercase output to match bash comparisons
    echo "${json}" | python3 -c "
import sys, json
val = json.load(sys.stdin)
# Navigate dotted key e.g. '.sealed' → 'sealed'
k = '${key}'.lstrip('.')
print(str(val[k]).lower())
"
  fi
}

# ── 1. Pre-flight checks ──────────────────────────────────────────
echo "==> Validating environment..."

kubectl cluster-info >/dev/null || {
  echo "ERROR: kubectl is not connected to a cluster"
  exit 1
}

kubectl get ns "${VAULT_NAMESPACE}" >/dev/null 2>&1 || {
  echo "ERROR: Namespace '${VAULT_NAMESPACE}' not found. Run: helm install vault ..."
  exit 1
}

# ── 2. Wait for pod phase=Running (not Ready — sealed pods fail readiness) ──
echo "==> Waiting for Vault pod to be Running (phase, not Ready)..."
for i in $(seq 1 30); do
  PHASE=$(kubectl get pod "${VAULT_POD}" -n "${VAULT_NAMESPACE}" \
    -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")

  if [ "${PHASE}" = "Running" ]; then
    echo "    Pod is Running."
    break
  fi

  echo "    Attempt ${i}/30: phase=${PHASE} — waiting..."
  sleep 3

  if [ "${i}" -eq 30 ]; then
    echo "ERROR: Vault pod did not reach Running phase within 90s"
    exit 1
  fi
done

# ── 3. Wait for Vault process to accept connections ───────────────
# vault status exits 0=unsealed, 2=sealed, 1=error (can't connect)
# We loop until we get 0 OR 2 — either means the API is up.
echo "==> Waiting for Vault API to respond..."
for i in $(seq 1 20); do
  EXIT_CODE=0
  kubectl exec -n "${VAULT_NAMESPACE}" "${VAULT_POD}" -- \
    vault status >/dev/null 2>&1 || EXIT_CODE=$?

  # exit 0 = unsealed, exit 2 = sealed — both mean API is up
  if [ "${EXIT_CODE}" -eq 0 ] || [ "${EXIT_CODE}" -eq 2 ]; then
    echo "    Vault API is responding (exit code: ${EXIT_CODE})"
    break
  fi

  echo "    Attempt ${i}/20: API not ready yet (exit code: ${EXIT_CODE})..."
  sleep 3

  if [ "${i}" -eq 20 ]; then
    echo "ERROR: Vault API did not respond within 60s"
    exit 1
  fi
done

# ── 4. Fetch full status JSON ─────────────────────────────────────
# || true because vault status exits 2 when sealed — that's expected
echo "==> Fetching Vault status..."
STATUS_JSON=$(kubectl exec -n "${VAULT_NAMESPACE}" "${VAULT_POD}" -- \
  vault status -format=json 2>/dev/null || true)

if [ -z "${STATUS_JSON}" ]; then
  echo "ERROR: Could not retrieve Vault status JSON"
  exit 1
fi

# ── 5. Initialise if needed ───────────────────────────────────────
INIT_STATUS=$(parse_json "${STATUS_JSON}" ".initialized")
echo "    initialized=${INIT_STATUS}"

if [ "${INIT_STATUS}" = "true" ]; then
  echo "    Vault already initialized — skipping."
else
  echo "==> Initializing Vault (5 shares, threshold 3)..."
  kubectl exec -n "${VAULT_NAMESPACE}" "${VAULT_POD}" -- \
    vault operator init -format=json > "${KEYS_FILE}"

  echo "  ✅  Keys saved to: ${KEYS_FILE}"
  echo "  ⚠️   Move this file to a secure location. Never commit it."
fi

# ── 6. Guard: keys file must exist before unsealing ──────────────
if [ ! -f "${KEYS_FILE}" ]; then
  echo "ERROR: ${KEYS_FILE} not found."
  echo "       If Vault was already initialized, provide the keys file manually."
  exit 1
fi

# ── 7. Unseal if needed ───────────────────────────────────────────
# Re-fetch status after potential init — still need || true (exits 2 when sealed)
echo "==> Checking seal status..."
STATUS_JSON=$(kubectl exec -n "${VAULT_NAMESPACE}" "${VAULT_POD}" -- \
  vault status -format=json 2>/dev/null || true)

SEALED=$(parse_json "${STATUS_JSON}" ".sealed")
echo "    sealed=${SEALED}"

if [ "${SEALED}" = "false" ]; then
  echo "    Vault is already unsealed."
else
  echo "==> Unsealing Vault (applying 3 of 5 keys)..."

  for i in 0 1 2; do
    KEY=$(parse_json "$(cat "${KEYS_FILE}")" ".unseal_keys_b64[${i}]")

    if [ -z "${KEY}" ] || [ "${KEY}" = "null" ]; then
      echo "ERROR: Could not extract unseal key index ${i} from ${KEYS_FILE}"
      exit 1
    fi

    echo "    Applying key $((i + 1))/3..."
    kubectl exec -n "${VAULT_NAMESPACE}" "${VAULT_POD}" -- \
      vault operator unseal "${KEY}"
  done

  # Confirm unsealed
  sleep 2
  STATUS_JSON=$(kubectl exec -n "${VAULT_NAMESPACE}" "${VAULT_POD}" -- \
    vault status -format=json 2>/dev/null || true)
  SEALED_AFTER=$(parse_json "${STATUS_JSON}" ".sealed")

  if [ "${SEALED_AFTER}" = "false" ]; then
    echo "  ✅  Vault successfully unsealed!"
  else
    echo "  ❌  Vault is still sealed after 3 keys — check the keys file."
    exit 1
  fi
fi

# ── 8. Port-forward ───────────────────────────────────────────────
echo "==> Setting up port-forward to localhost:8200..."
PF_PID=""

if lsof -i :8200 >/dev/null 2>&1; then
  echo "    Port 8200 already in use — assuming port-forward already running."
else
  kubectl port-forward svc/vault 8200:8200 \
    -n "${VAULT_NAMESPACE}" >/dev/null 2>&1 &
  PF_PID=$!
  echo "    Port-forward PID: ${PF_PID}"
  sleep 2
fi

# ── 9. Confirm HTTP endpoint is reachable ─────────────────────────
echo "==> Confirming Vault HTTP endpoint..."
for i in $(seq 1 10); do
  if curl -sf http://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
    echo "    ✅  http://127.0.0.1:8200 is reachable"
    break
  fi
  echo "    Attempt ${i}/10 — waiting..."
  sleep 2
done

# ── 10. Print export block ────────────────────────────────────────
ROOT_TOKEN=$(parse_json "$(cat "${KEYS_FILE}")" ".root_token")

if [ -z "${ROOT_TOKEN}" ] || [ "${ROOT_TOKEN}" = "null" ]; then
  echo "ERROR: Could not extract root_token from ${KEYS_FILE}"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅  Phase 1 complete. Copy and run these exports, then apply:"
echo ""
echo "  export VAULT_ADDR=http://127.0.0.1:8200"
echo "  export VAULT_TOKEN=${ROOT_TOKEN}"
echo "  export TF_VAR_mysql_vault_admin_password='VaultP@ssw0rd'"
echo "  export TF_VAR_postgres_vault_admin_password='VaultP@ssw0rdPG'"
echo "  export TF_VAR_catalog_db_password='CatalogP@ss'"
echo "  export TF_VAR_appointments_db_password='AppointmentsP@ss'"
echo ""
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
echo ""
if [ -n "${PF_PID}" ]; then
  echo "  To stop port-forward: kill ${PF_PID}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
