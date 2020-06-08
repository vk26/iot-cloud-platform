require 'json'

1000.times do
  params = {
    device_id: "dev-id-#{rand(1000)}",
    telemetry_key: %w[pressure temperature].sample,
    telemetry_value: rand(60) + 60
  }.to_json
  cmd = "echo 'POST||/api/telemetry|||| #{params}' | python ./ammo-generator.py >> ammo.txt"
  
  system(cmd)
end
