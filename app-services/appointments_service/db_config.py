# appointments_service/db_config.py
import os

APPOINTMENT_DB_USER = os.getenv("APPOINTMENT_DB_USER")
APPOINTMENT_DB_PASS = os.getenv("APPOINTMENT_DB_PASS")
APPOINTMENT_DB_HOST = os.getenv("APPOINTMENT_DB_HOST", "localhost")
APPOINTMENT_DB_PORT = int(os.getenv("APPOINTMENT_DB_PORT", 3306))
APPOINTMENT_DB_NAME = os.getenv("APPOINTMENT_DB_NAME", "appointments_svs")

# Database connection configuration for the APPOINTMENTS SERVICE
# CATALOG_DB_USER = "appointments_user"  # <--- CHANGED
# CATALOG_DB_PASS = "AppointmentsP@ss"   # <--- CHANGED to the new password
# CATALOG_DB_HOST = "192.168.56.1"  # <--- CHANGED to 127.0.0.1 for local dev
# CATALOG_DB_PORT = 3306
# CATALOG_DB_NAME = "appointments_svs"  # <--- CHANGED to appointments_svs