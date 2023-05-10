# InfluxDB v2 Scenario

This scenario publishes k6 metrics from each pod into an InfluxDB. The Docker compose also provides a Grafana
dashboard for viewing the results. 

> This scenario depends upon having the Kubernetes cluster setup as described in the main [README.md](../../README.md).

## Start InfluxDB
A [docker-compose.yml](docker-compose.yml) has been provided which contains the InfluxDB v2 and Grafana instances.
Start them up by executing the following command from the project root.

```shell
docker compose -f scenario/influxdb/docker-compose.yml up -d
```

Once started, you'll now be able to access Grafana at http://localhost:3000/.

## Trigger a test
The [k6 resource](k6-output-influxdb.yaml) contains all configuration required for k6 to publish real-time metrics.
For more information about the configuration settings, see the [xk6-output-influxdb](https://github.com/grafana/xk6-output-influxdb)
documentation.

```shell
./run-kube.sh scenario/influxdb/k6-output-influxdb.yaml
```

## Teardown your setup
When you've completed your testing, but sure to reclaim resources by shutting down your InfluxDB and Grafana services.

```shell
docker compose -f scenario/influxdb/docker-compose.yml down
```
