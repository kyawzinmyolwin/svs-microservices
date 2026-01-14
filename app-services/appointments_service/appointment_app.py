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

@app.route("/api/v1/appointments", methods=["POST"])
def create_appointment():
    data = request.get_json()
    appt_datetime = datetime.strptime(data['appt_datetime'], "%Y-%m-%dT%H:%M")
    
    # Business Rule Validations [7, 8]
    if appt_datetime < datetime.now():
        return jsonify({"error": "Date cannot be in the past"}), 400
    if appt_datetime.weekday() == 6:
        return jsonify({"error": "Closed on Sundays"}), 400

    cursor = db_connector.get_cursor()
    cursor.execute("INSERT INTO appointments (customer_id, appt_datetime, notes) VALUES (%s, %s, %s)", 
                   (data['customer_id'], appt_datetime, data['notes']))
    
    new_id = cursor.lastrowid # Get ID for the junction table [6]
    service_data = [(new_id, sid) for sid in data['service_ids']]
    cursor.executemany("INSERT INTO appointment_services (appt_id, service_id) VALUES (%s, %s)", service_data)
    return jsonify({"status": "created", "appt_id": new_id}), 201

#################################################################

@app.route("/api/v1/appointments/<int:appt_id>", methods=["DELETE"])
def delete_appointment(appt_id):
    cursor = db_connector.get_cursor()
    # CASCADE constraint automatically cleans up appointment_services table [4]
    cursor.execute("DELETE FROM appointments WHERE appt_id=%s", (appt_id,))
    cursor.close()
    return jsonify({"status": "deleted"}), 200

#################################################################

# Health check endpoint
@app.route("/health", methods=["GET"])
def health_check():
    is_db_healthy = db_connector.check_db_health()
    status = "healthy" if is_db_healthy else "unhealthy"
    return jsonify({"status": status}), (200 if is_db_healthy else 500) 
#################################################################
# Web UI Routes
#################################################################
# @app.route("/health")
# def health():
#     return {"status": "UP"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5003)

