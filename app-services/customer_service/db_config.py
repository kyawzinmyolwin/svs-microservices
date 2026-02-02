# catalog_service/db_config.py
import os

# Database connection config for Vault integration
with open("/vault/secrets/db-creds") as f:
    for line in f:
        key, value = line.strip().split("=")
        os.environ[key] = value

db_user = os.getenv("DB_USERNAME")
db_pass = os.getenv("DB_PASSWORD")
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