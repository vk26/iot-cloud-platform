CREATE TABLE IF NOT EXISTS telemetry (
  client_id UInt64,
  device_id String,
  device_type String,
  telemetry_key String,
  telemetry_value_int Int64,
  treshold_exceeded UInt8,
  region String,
  city String,
  department String,
  timestamp DateTime
) ENGINE = MergeTree()
PARTITION BY (client_id, toYYYYMMDD(timestamp))
ORDER BY (client_id, device_id)
SETTINGS index_granularity = 8192


CREATE TABLE IF NOT EXISTS telemetry_kafka (
  client_id UInt64,
  device_id String,
  device_type String,
  telemetry_key String,
  telemetry_value_int Int64,
  treshold_exceeded UInt8,
  region String,
  city String,
  department String,
  timestamp DateTime
) ENGINE = Kafka SETTINGS
            kafka_broker_list = '172.23.0.4', 
            kafka_topic_list = 'telemetry_stream',
            kafka_group_name = 'telemetry',
            kafka_format = 'JSONEachRow',
            kafka_num_consumers = 8


CREATE MATERIALIZED VIEW IF NOT EXISTS telemetry_consumer TO telemetry
        AS SELECT * FROM telemetry_kafka
