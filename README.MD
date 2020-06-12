# IoT Cloud Platform

## Goals

* handle highload telemetry requests (successfully passing 100-200k+ RPS load testing in one machine)
* horizontal scalability of all components
* implement user experience (real-time IoT-monitoring, BI-analytics, data-visualization)
* cheap solution 

# System Design
![System deisgn](./images/system_design.png)

# Technology stack
![Technology stack](./images/techstack.png)

# Tarantool cluster topology
![Tarantool cluster](./images/tarantool_cluster.png)

# Benchmarks
Load Testing using yandex-tank. Laptop CPU i7 4+4 Cores, 16 RAM, SSD

Tarantool cluster config: 4 routers(API), 4 storages shards

**200k RPS:**

https://overload.yandex.net/279979
