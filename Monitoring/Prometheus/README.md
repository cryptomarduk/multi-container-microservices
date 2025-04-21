# Prometheus Configuration

This directory contains the Prometheus configuration files for monitoring the microservices.

The main configuration file is `prometheus.yml`, which defines the scrape configurations for all services in the stack.

## Endpoints Monitored

- Python Service: `http://python-service:5000/metrics`
- Node.js Service: `http://node-service:3000/metrics`
- Nginx: `http://nginx-proxy:80/metrics`
- MongoDB (via exporter): `http://mongodb-exporter:9216/metrics`
- Redis (via exporter): `http://redis-exporter:9121/metrics`

## Alert Rules

Alert rules are defined in `alert_rules.yml` and include:

- High service error rates
- Service availability issues
- Resource utilization thresholds
- Unusual traffic patterns

## Configuration Files

- `prometheus.yml`: Main configuration file
- `alert_rules.yml`: Alert definitions
- `recording_rules.yml`: Recording rules for complex queries

## Adding New Services

To add a new service to be monitored:

1. Add a new job definition to `prometheus.yml`
2. Include appropriate labels for service identification
3. Define the metrics path and scrape interval
4. Add any service-specific alert rules to `alert_rules.yml`
