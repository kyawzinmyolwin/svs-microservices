#!/bin/bash

# List of target files
FILES=(
"app-services/appointments_service/appointment_app.py"
"app-services/catalog_service/catalog_app.py"
"app-services/customer_service/customer_app.py"
"app-services/frontend_service/app.py"
)

COMMENT="#Initiate the Runner1.5"

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    # Check if comment already exists
    if ! grep -Fxq "$COMMENT" "$FILE"; then
      echo "$COMMENT" >> "$FILE"
      echo "Updated: $FILE"
    else
      echo "Skipped (already exists): $FILE"
    fi
  else
    echo "File not found: $FILE"
  fi
done