version: '3.8'

services:

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:9090/-/healthy"]
      interval: 10s
      timeout: 5s
      retries: 5

  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    depends_on:
      - prometheus
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3000/api/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  suricata:
    image: jasonish/suricata:latest
    container_name: suricata
    network_mode: host
    cap_add:
      - NET_ADMIN
      - SYS_NICE
    volumes:
      - ./suricata_logs:/var/log/suricata
    healthcheck:
      test: ["CMD-SHELL", "pgrep suricata > /dev/null || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  flask_ui:
    build: ./flask_app
    container_name: flask_ui
    ports:
      - "5000:5000"
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5000"]
      interval: 10s
      timeout: 5s
      retries: 5
