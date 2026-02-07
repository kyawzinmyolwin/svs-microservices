# catalog_service/db_config.py
import os
import signal
import logging

## Add this due to circular import issues with db_connector ##
# Define the path where Vault injects secrets
VAULT_SECRET_PATH = "/vault/secrets/db-creds"

def load_vault_secrets():
    """Reads the Vault file and updates os.environ"""
    if not os.path.exists(VAULT_SECRET_PATH):
        logging.warning(f"Vault secret file {VAULT_SECRET_PATH} not found!")
        return

    logging.info("Refreshing Vault secrets from disk...")
    with open(VAULT_SECRET_PATH) as f:
        for line in f:
            if "=" in line:
                key, value = line.strip().split("=", 1)
                os.environ[key] = value

def handle_sighup(signum, frame):
    """Callback for Vault Agent's SIGHUP signal"""
    load_vault_secrets()
    # If using a connection pool (like SQLAlchemy), you should recreate it here!
    logging.info("Secrets reloaded successfully.")

# Register the signal handler
signal.signal(signal.SIGHUP, handle_sighup)

# Initial load on startup
load_vault_secrets()

# Use functions instead of static variables to ensure fresh data
def get_db_user(): return os.getenv("DB_USERNAME")
def get_db_pass(): return os.getenv("DB_PASSWORD")

# Database connection config for Vault integration
# with open("/vault/secrets/db-creds") as f:
#     for line in f:
#         key, value = line.strip().split("=")
#         os.environ[key] = value

# db_user = os.getenv("DB_USERNAME")
# db_pass = os.getenv("DB_PASSWORD")
##==--- IGNORE ---==##

CUSTOMER_DB_HOST = os.getenv("CUSTOMER_DB_HOST", "localhost")
CUSTOMER_DB_PORT = int(os.getenv("CUSTOMER_DB_PORT", 3306))
CUSTOMER_DB_NAME = os.getenv("CUSTOMER_DB_NAME", "customers_svs")

# Using environment variables for better security and flexibility

# CUSTOMER_DB_USER = os.getenv("CUSTOMER_DB_USER")
# CUSTOMER_DB_PASS = os.getenv("CUSTOMER_DB_PASS")
# CUSTOMER_DB_HOST = os.getenv("CUSTOMER_DB_HOST", "localhost")
# CUSTOMER_DB_PORT = int(os.getenv("CUSTOMER_DB_PORT", 3306))
# CUSTOMER_DB_NAME = os.getenv("CUSTOMER_DB_NAME", "customers_svs")

# Database connection configuration for the CATALOG SERVICE
# CATALOG_DB_USER = "customers_user"  # <--- CHANGED
# CATALOG_DB_PASS = "CustomersP@ss"   # <--- CHANGED to the new password
# CATALOG_DB_HOST = "192.168.56.1"  # <--- CHANGED to 127.0.0.1 for local dev
# CATALOG_DB_PORT = 3306
# CATALOG_DB_NAME = "customers_svs"

# CATALOG_DB_USER = "root"  # <--- CHANGED
# CATALOG_DB_PASS = "P@ssw0rd"   # <--- CHANGED to the new password
# CATALOG_DB_HOST = "192.168.56.1"  
# CATALOG_DB_PORT = 3306
# CATALOG_DB_NAME = "svs"