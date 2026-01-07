#catalog_app.py
from flask import Flask, jsonify
import db_connector

app = Flask(__name__)
db_connector.init_db(app)

# --- Service Logic Functions ---

def get_all_services_from_db():
    cursor = None
    try:
        cursor = db_connector.get_cursor()
        qstr = "SELECT service_id, service_name, price FROM services;"
        cursor.execute(qstr)
        rows = cursor.fetchall()

        services = []
        for r in rows or []:
            services.append({
                "service_id": r["service_id"],
                "service_name": r["service_name"],
                "price": r["price"]
            })
        return services

    except Exception as e:
        app.logger.exception("Database error while fetching services: %s", e)
        return None

    finally:
        if cursor:
            cursor.close()


def service_analytics():
    cursor = None
    try:
        cursor = db_connector.get_cursor()
        analytics_qstr = """
        SELECT
            s.service_name,
            s.price,
            COUNT(aps.service_id) AS total_count_used,
            COALESCE(SUM(s.price), 0) AS total_revenue
        FROM services s
        LEFT JOIN appointment_services aps
            ON s.service_id = aps.service_id
        GROUP BY s.service_id, s.service_name, s.price
        ORDER BY total_revenue DESC
        """

        cursor.execute(analytics_qstr)
        rows = cursor.fetchall()

        return [dict(row) for row in rows]

    except Exception as e:
        app.logger.exception("Database error while fetching service analytics: %s", e)
        return None

    finally:
        if cursor:
            cursor.close()


# --- API Endpoints ---

@app.route("/health")
def health():
    return {"status": "ok"}, 200


@app.route("/api/v1/services", methods=["GET"])
def service_list_api():
    services_data = get_all_services_from_db()

    if services_data is None:
        return jsonify({"message": "Could not retrieve service data."}), 500

    return jsonify({
        "status": "success",
        "count": len(services_data),
        "services": services_data
    }), 200


@app.route("/api/v1/services/service_analytics", methods=["GET"])
def service_analytics_api():
    stats = service_analytics()

    if stats is None:
        return jsonify({"message": "Could not retrieve service analytics."}), 500

    return jsonify({
        "status": "success",
        "count": len(stats),
        "service_stats": stats
    }), 200


@app.route("/api/v1/services/<int:service_id>", methods=["GET"])
def get_service_by_id(service_id):
    return jsonify({"message": f"Service details for ID {service_id}"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
