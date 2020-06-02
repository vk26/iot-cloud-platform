echo "POST||/api/telemetry|||| \
  { \"device_id\": \"dev04\", \"device_name\": \"Device_04\", \"telemetry_key\": \"pressure\", \"telemetry_value\": 109 }" \
  | python ./ammo-generator.py >> ammo.txt
