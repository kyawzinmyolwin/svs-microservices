# db_connector.py
from flask import g
import MySQLdb
from MySQLdb import cursors
from MySQLdb import OperationalError
import db_config


def get_connection_params():
    creds = db_config.load_db_creds()

    return {
        "user": creds["DB_USERNAME"],
        "password": creds["DB_PASSWORD"],
        "host": db_config.CUSTOMER_DB_HOST,
        "database": db_config.CUSTOMER_DB_NAME,
        "port": db_config.CUSTOMER_DB_PORT,
        "autocommit": True,
        "connect_timeout": 5,
    }


def check_db_health():
    try:
        db = MySQLdb.connect(**get_connection_params())
        db.close()
        return True
    except Exception:
        return False


def init_db(app):
    app.teardown_appcontext(close_db)


def get_db():
    try:
        if "db" not in g:
            g.db = MySQLdb.connect(**get_connection_params())
        return g.db

    except OperationalError as e:
        # MySQL auth failure codes
        if e.args[0] in (1044, 1045):
            # Credentials expired → reconnect with fresh Vault creds
            if "db" in g:
                g.db.close()
                g.pop("db", None)

            g.db = MySQLdb.connect(**get_connection_params())
            return g.db

        raise

def get_cursor():
    return get_db().cursor(cursorclass=cursors.DictCursor)


def close_db(exception=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()
