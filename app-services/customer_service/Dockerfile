FROM python:3.11-slim

# Prevent Python from writing pyc files & buffering logs
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies for mysqlclient
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first (better Docker cache)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Tell Flask which app to run
ENV FLASK_APP=customer_app.py
ENV FLASK_ENV=production

EXPOSE 5002

CMD ["flask", "run", "--host=0.0.0.0", "--port=5002"]
