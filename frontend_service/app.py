# frontend_service/app.py

import os
import requests
from flask import Flask, render_template, request, redirect, flash
from datetime import datetime

app = Flask(__name__)



CUSTOMER_SVC = os.getenv("CUSTOMER_SVC_URL")
CATALOG_SVC = os.getenv("CATALOG_SVC_URL")
APPOINTMENT_SVC = os.getenv("APPOINTMENTS_SVC_URL")
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev-secret-key")

#Testing connectivity
# print("APPOINTMENTS_SVC_URL =", os.getenv("APPOINTMENTS_SVC_URL"))

# ---------- Utility ----------

def fetch_json(url):
    try:
        resp = requests.get(url, timeout=3)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        app.logger.error(f"Error calling {url}: {e}")
        return None

# ---------- Routes ----------

@app.route("/")
def home():
    return render_template("home.html")
# @app.route("/")
# def home():
#     return "<h1>Frontend Service UP</h1>"


@app.route("/customers")
def customers_page():
    data = fetch_json(f"{CUSTOMER_SVC}/api/v1/customers")
    customers = data["customers"] if data else []
    return render_template("customers.html", customers=customers)

@app.route("/customers/<int:customer_id>")
def customer_detail_page(customer_id):
    data = fetch_json(f"{CUSTOMER_SVC}/api/v1/customers/{customer_id}")
    customer = data if data else {}
    return render_template("customer_manage.html", customer=customer, is_edit=True)

# Create customer form
@app.route("/customers/new", methods=["GET", "POST"])
def create_customer_ui():
    if request.method == "POST":
        payload = {
            "first_name": request.form["first_name"],
            "family_name": request.form["family_name"],
            "email": request.form.get("email"),
            "phone": request.form["phone"],
            "date_joined": request.form["date_joined"]
        }

        r = requests.post(f"{CUSTOMER_SVC}/api/v1/customers", json=payload)

        if r.status_code != 201:
            flash(r.json()["error"], "error")
            return redirect(request.referrer)

        flash("Customer created successfully", "success")
        return redirect("/customers")

    return render_template("customer_manage.html", is_edit=False)

#Update the form action URL in the template
@app.route("/customers/<int:id>/edit", methods=["POST"])
def update_customer_ui(id):
    payload = {
        "first_name": request.form["first_name"],
        "family_name": request.form["family_name"],
        "email": request.form["email"],
        "phone": request.form["phone"],
    }

    resp = requests.put(
        f"{CUSTOMER_SVC}/api/v1/customers/{id}",
        json=payload
    )

    if resp.status_code != 200:
        flash(resp.json()["error"], "error")
        return redirect(request.referrer)

    flash("Customer updated successfully", "success")
    return redirect(f"/customers/{id}")


########################################################
## New routes for services and appointments
########################################################
@app.route("/services")
def services_page():
    data = fetch_json(f"{CATALOG_SVC}/api/v1/services")
    services = data["services"] if data else []
    return render_template("services.html", services=services)

@app.route("/services/service_analytics")
def service_analytics_page():
    data = fetch_json(f"{CATALOG_SVC}/api/v1/services/service_analytics")
    service_stats = data["service_stats"] if data else []
    return render_template("service_analytics.html", service_stats=service_stats)


@app.route("/appointments")
def appointments_page():
    data = fetch_json(f"{APPOINTMENT_SVC}/api/v1/appointments")
    appointments = data["appointments"] if data else []
    return render_template("appointments.html", appointments=appointments)

@app.route("/health")
def health():
    return {"status": "UP"}, 200

if __name__ == "__main__":
    app.run(port=5000, debug=True)
