# catalog_service/db_connector.py

from flask import g
import MySQLdb
from MySQLdb import cursors
import db_config # Import local config

# Database connection parameters for the CatalogDB
# connection_params = {
#     "user": db_config.CATALOG_DB_USER,
#     "password": db_config.CATALOG_DB_PASS,
#     "host": db_config.CATALOG_DB_HOST,
#     "database": db_config.CATALOG_DB_NAME,
#     "port": db_config.CATALOG_DB_PORT,
#     "autocommit": True,
#     "connect_timeout": 5,
# }

# Database connection parameters for the CatalogDB
connection_params = {
    "user": db_config.db_user,
    "password": db_config.db_pass,
    "host": db_config.CATALOG_DB_HOST,
    "database": db_config.CATALOG_DB_NAME,
    "port": db_config.CATALOG_DB_PORT,
    "autocommit": True,
    "connect_timeout": 5,
}

def check_db_health():
    try:
        db = MySQLdb.connect(**connection_params)
        db.close()
        return True
    except Exception:
        return False

def init_db(app):
    """Initialize app context teardown."""
    app.teardown_appcontext(close_db)

def get_db():
    """Get MySQL database connection for current request."""
    if "db" not in g:
        g.db = MySQLdb.connect(**connection_params)
    return g.db

def get_cursor():
    """Get a new MySQL dictionary cursor for current request."""
    return get_db().cursor(cursorclass=cursors.DictCursor)

def close_db(exception=None):
    """Close database connection at end of request."""
    db = g.pop("db", None)
    if db is not None:
        db.close()