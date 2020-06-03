require 'delivery_boy'
require 'kafka'
require 'json'
require 'logger'
require 'active_support/core_ext/hash'
require 'faker'

DeliveryBoy.configure do |config|
  config.brokers = ENV.fetch('KAFKA_BROKER_LIST') { ['localhost:9092'] }
  config.log_level = :error
end

logger = Logger.new(STDOUT)

namespace :kafka do
  task :produce_telemetry_sample do
    logger.info 'Start producing messages ...'
    10_000.times do |i|
      message =  {
        client_id: 1,
        device_id: "dev_#{rand(100) + 1}",
        device_type: "sensor_#{rand(10) + 1}",
        telemetry_key: %w[temperature pressure].sample,
        telemetry_value_int: [*50..180].sample,
        treshold_exceeded: Faker::Boolean.boolean(true_ratio: 0.1),
        region: %w[Central Northwest South Ural Siberia far-East].sample,
        city: %w[Saint-Petersburg Moscow Krasnodar Ekaterinburg Novosibirsk Krasnoyarsk Irkutsk Vladivostok].sample,
        department: %w[Department_01 Department_02 Department_03].sample,
        timestamp: (Faker::Date.backward(days: 90) + [*8..20].sample.hours).utc.to_i # unixtime
      }.stringify_keys
      DeliveryBoy.deliver(message.to_json, topic: 'telemetry_stream')
    end
    logger.info 'Messages sent successfully!'
  end
  
  task :consumer_ouput_telemetry_stream do
    logger.info 'Listening Kafka queue telemetry_stream ...'
    logger.level = :error
    kafka = Kafka.new(seed_brokers: 'kafka://localhost:9092', logger: logger)
    consumer = kafka.consumer(
      group_id: 'telemetry',

      # Increase offset commit frequency to once every 5 seconds.
      offset_commit_interval: 5,

      # Commit offsets when 100 messages have been processed.
      offset_commit_threshold: 100,

      # Increase the length of time that committed offsets are kept.
      offset_retention_time: 7 * 60 * 60
    )
    consumer.subscribe('telemetry_stream', start_from_beginning: false)
    consumer.each_message do |message|
      record = { offset: message.offset, value: message.value }
      puts record
    end
  end
end
