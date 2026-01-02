#appointments_service/appointment_app.py
from flask import Flask, jsonify, request
import db_connector
from datetime import datetime

app = Flask(__name__)
db_connector.init_db(app) # Initializes the DB connection for this service

# --- Service Logic Functions ---
def get_appointments():
    cursor = db_connector.get_cursor() # [12, 13]
    # Query only local appointment tables
    query = """
    SELECT a.appt_id, a.customer_id, a.appt_datetime, a.notes, group_concat(aps.service_id) as service_ids
    FROM appointments a
    LEFT JOIN appointment_services aps ON a.appt_id = aps.appt_id
    GROUP BY a.appt_id
    ORDER BY a.appt_datetime ASC
    """
    cursor.execute(query)
    rows = cursor.fetchall()
    cursor.close()

    # Apply the "is_future" logic found in the monolith [6, 7]
    for appt in rows:
        if appt.get('appt_datetime'):
            appt['is_future'] = appt['appt_datetime'] > datetime.now()
        else:
            appt['is_future'] = False
    return rows

# --- API Endpoints ---
@app.route("/api/v1/appointments", methods=["GET"])
def api_get_appointments():
    appointments = get_appointments()
    return jsonify({"appointments": appointments})
# Additional endpoints (CREATE, UPDATE, DELETE) would go here

# Health check endpoint
@app.route("/health", methods=["GET"])
def health_check():
    is_db_healthy = db_connector.check_db_health()
    status = "healthy" if is_db_healthy else "unhealthy"
    return jsonify({"status": status}), (200 if is_db_healthy else 500) 

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5003)

