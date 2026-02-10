# db_config.py
import os

VAULT_DB_CREDS_PATH = "/vault/secrets/db-creds"

CUSTOMER_DB_HOST = os.getenv("CUSTOMER_DB_HOST", "localhost")
CUSTOMER_DB_PORT = int(os.getenv("CUSTOMER_DB_PORT", 3306))
CUSTOMER_DB_NAME = os.getenv("CUSTOMER_DB_NAME", "customers_svs")


def load_db_creds():
    """
    Always read fresh credentials from Vault-injected file
    """
    creds = {}
    with open(VAULT_DB_CREDS_PATH) as f:
        for line in f:
            key, value = line.strip().split("=", 1)
            creds[key] = value
    return creds
