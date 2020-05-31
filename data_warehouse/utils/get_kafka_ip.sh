docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' iot-cloud-platform_kafka_1
