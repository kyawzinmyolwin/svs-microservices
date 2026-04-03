# Invalid URL Error

## Error
Invalid URL '/api/v1/appointments': No scheme supplied.

## Root Cause
ENV Value mismatched in docker-compose.yaml and .env file

## Fix


## Key Takeaway

# Pod stuck at init
```
NAME                                READY   STATUS     RESTARTS   AGE
svs-app-customer-7b9b5cb78c-qjcqw   0/2     Init:0/1   0          32m
```
# Check the init container logs
```
kubectl logs svs-app-customer-7b9b5cb78c-qjcqw -c vault-agent-init  
```
# 500 Server Error: INTERNAL SERVER ERROR for url: http://svs-service-customer:5002/api/v1/customers

Login to the svs-app-customer pod and curl http://localhost:5002/api/v1/customers

```
# curl http://localhost:5002/api/v1/customers
Expected Result: All records should show
<!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```
Build temporary mysql client pod to test the connectivity
```
kubectl run mysql-client --rm -it --image=mysql:8.0 -- /bin/bash
```
```
mysql -u v-root-svs-custom-6Q5aLnSYboWhZX -p -h 192.168.56.1 customers_svs
```
Able to access the Database.

#### Check what database username and password injected to the pod
```
kubectl exec -it <pod-name> -n svs-microservices -c svs-app -- cat /vault/secrets/db-creds
cat /vault/secrets/db-creds
```
#### Check what is the correct route name in customer_app.py

Good systematic approach — since DB connectivity is confirmed, let's work through the likely culprits layer by layer.

**1. Check the app logs first (most likely to reveal the root cause)**

```bash
kubectl logs <pod-name> -n svs-microservices -c svs-app
# Or tail live logs while hitting the endpoint
kubectl logs -f <pod-name> -n svs-microservices -c svs-app
```

Also check the Vault agent sidecar logs in case secret renewal is failing:
```bash
kubectl logs <pod-name> -n svs-microservices -c vault-agent
```

---

**2. Verify the secret file is being parsed correctly**

Based on your `db_config.py`, it splits on `=` — which breaks if the password contains `=` or special characters. Exec into the pod and check:

```bash
cat -A /vault/secrets/db-creds
```

Look for unexpected characters, trailing whitespace, or extra newlines. Your current parser:

```python
key, value = line.strip().split("=")  # Breaks on passwords like "P@ss=word"
```

A safer version:

```python
key, value = line.strip().split("=", 1)  # maxsplit=1 handles = in values
```

---

**3. Verify env vars are actually set inside the app container**

```bash
kubectl exec -it <pod-name> -n svs-microservices -c svs-app -- env | grep -E "DB_|CUSTOMER_"
```

If `DB_USERNAME` and `DB_PASSWORD` are empty, the file parsing is failing silently.

---

**4. Test DB connection from inside the pod directly**

```bash
mysql -h $CUSTOMER_DB_HOST -P $CUSTOMER_DB_PORT -u $DB_USERNAME -p$DB_PASSWORD $CUSTOMER_DB_NAME
```

This confirms whether the credentials work end-to-end from the app container's network context (not just from your manual test).

---

**5. Check if the Flask route itself has an unhandled exception**

Hit the endpoint and immediately grab logs:
```bash
curl http://localhost:5002/api/v1/customers
kubectl logs <pod-name> -n svs-microservices -c svs-app --tail=50
```

A 500 from Flask usually means an unhandled Python exception — the traceback will be in the logs.

---




