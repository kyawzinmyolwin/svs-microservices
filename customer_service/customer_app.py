#customer_app.py
from flask import Flask, jsonify, request
import db_connector
import re
from datetime import datetime, date

NAME_REGEX = r"^[A-Za-zÀ-ÖØ-öø-ÿ' -]+$"
NZ_PHONE_REGEX = r"^02\d{7,9}$"

app = Flask(__name__)
db_connector.init_db(app)

# ---------- Helpers ----------

def fetch_all_customers():
    cursor = db_connector.get_cursor()
    cursor.execute("""
            SELECT customer_id, first_name, family_name, email, phone
            FROM customers
    """)
    rows = cursor.fetchall()
    cursor.close()
    return rows

def fetch_customer_by_id(customer_id):
    cursor = db_connector.get_cursor()
    cursor.execute("""
        SELECT customer_id, first_name, family_name, email, phone
        FROM customers WHERE customer_id = %s
    """, (customer_id,))
    row = cursor.fetchone()
    cursor.close()
    return row

# ---------- CRUD APIs ----------

# CREATE
@app.route("/api/v1/customers", methods=["POST"])
def create_customer():
    data = request.get_json()

    first_name = data.get("first_name", "").strip()
    family_name = data.get("family_name", "").strip()
    email = data.get("email", "").strip()
    phone = data.get("phone", "").strip()
    date_joined_str = data.get("date_joined")

    # ---------- Validation ----------
    if not all([first_name, family_name, phone]):
        return jsonify({"error": "Missing required fields"}), 400

    if not re.match(NAME_REGEX, first_name) or not re.match(NAME_REGEX, family_name):
        return jsonify({"error": "Invalid characters in name"}), 400

    normalized_phone = re.sub(r"[ \-\(\)]", "", phone)
    if not re.match(NZ_PHONE_REGEX, normalized_phone):
        return jsonify({"error": "Invalid NZ phone format"}), 400

    today = date.today()

    date_joined = None
    if not date_joined_str:
        date_joined = today
    else:
        try:
            # expect ISO-like "YYYY-MM-DDTHH:MM" or adjust as needed
            input_date = datetime.strptime(date_joined_str, "%Y-%m-%dT%H:%M").date()
        except ValueError:
            # try plain date YYYY-MM-DD as fallback
            try:
                input_date = datetime.strptime(date_joined_str, "%Y-%m-%d").date()
            except ValueError:
                return jsonify({"error": "Invalid date format for date_joined. Use YYYY-MM-DD or YYYY-MM-DDTHH:MM."}), 400

        if input_date > today:
            return jsonify({"error": "Date Joined cannot be in the future."}), 400

        date_joined = input_date

    cursor = db_connector.get_cursor()

    # ---------- Duplicate phone check ----------
    cursor.execute("""
        SELECT customer_id
        FROM customers
        WHERE REPLACE(REPLACE(REPLACE(REPLACE(phone,' ',''),'-',''),'(',''),')','') = %s
    """, (normalized_phone,))

    if cursor.fetchone():
        cursor.close()
        return jsonify({"error": "Phone number already in use"}), 409

    # ---------- Insert ----------
    cursor.execute("""
        INSERT INTO customers (first_name, family_name, email, phone, date_joined)
        VALUES (%s, %s, %s, %s, %s)
    """, (
        first_name,
        family_name,
        email or None,
        phone,
        date_joined
    ))
    cursor.close()

    return jsonify({"status": "created"}), 201

# READ ALL
@app.route("/api/v1/customers", methods=["GET"])
def list_customers():
    customers = fetch_all_customers()
    return jsonify({
        "count": len(customers),
        "customers": customers
    })

# READ ONE
@app.route("/api/v1/customers/<int:customer_id>", methods=["GET"])
def get_customer(customer_id):
    customer = fetch_customer_by_id(customer_id)
    if not customer:
        return jsonify({"message": "Customer not found"}), 404
    return jsonify(customer)

########################################################
# # UPDATE
# @app.route("/api/v1/customers/<int:customer_id>", methods=["PUT"])
# def update_customer(customer_id):
#     data = request.get_json()

#     cursor = db_connector.get_cursor()
#     cursor.execute("""
#         UPDATE customers
#         SET first_name=%s, family_name=%s, email=%s, phone=%s
#         WHERE customer_id=%s
#     """, (
#         data["first_name"],
#         data["family_name"],
#         data["email"],
#         data.get("phone"),
#         customer_id
#     ))
#     cursor.close()

#     return jsonify({"status": "updated"})
########################################################

########################################################
@app.route("/api/v1/customers/<int:customer_id>", methods=["PUT"])
def update_customer(customer_id):
    data = request.get_json()

    first_name = data.get("first_name", "").strip()
    family_name = data.get("family_name", "").strip()
    email = data.get("email", "").strip()
    phone = data.get("phone", "").strip()

    # ---------- Validation ----------
    if not all([first_name, family_name, phone]):
        return jsonify({"error": "Missing required fields"}), 400

    if not re.match(NAME_REGEX, first_name) or not re.match(NAME_REGEX, family_name):
        return jsonify({"error": "Invalid characters in name"}), 400

    normalized_phone = re.sub(r"[ \-\(\)]", "", phone)
    if not re.match(NZ_PHONE_REGEX, normalized_phone):
        return jsonify({"error": "Invalid NZ phone format"}), 400

    cursor = db_connector.get_cursor()

    # ---------- Duplicate phone check ----------
    cursor.execute("""
        SELECT customer_id
        FROM customers
        WHERE REPLACE(REPLACE(REPLACE(REPLACE(phone,' ',''),'-',''),'(',''),')','') = %s
        AND customer_id != %s
    """, (normalized_phone, customer_id))

    if cursor.fetchone():
        cursor.close()
        return jsonify({"error": "Phone number already in use"}), 409

    # ---------- Update ----------
    cursor.execute("""
        UPDATE customers
        SET first_name=%s, family_name=%s, email=%s, phone=%s
        WHERE customer_id=%s
    """, (first_name, family_name, email, phone, customer_id))

    cursor.close()

    return jsonify({"status": "updated"}), 200

########################################################
# DELETE
@app.route("/api/v1/customers/<int:customer_id>", methods=["DELETE"])
def delete_customer(customer_id):
    cursor = db_connector.get_cursor()
    cursor.execute("DELETE FROM customers WHERE customer_id=%s", (customer_id,))
    cursor.close()

    return jsonify({"status": "deleted"})

if __name__ == "__main__":
    app.run(port=5002, debug=True)
