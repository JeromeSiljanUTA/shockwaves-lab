# monitoring

Grafana + Loki + Alloy for the lab. The first job is the nginx access and
error logs from `jeromesiljan-com`.

- Grafana: `http://grafana.nemesis.home.arpa` (proxied by NixOS nginx to `127.0.0.1:3030`)
- Loki: internal only, `http://loki:3100`
- Alloy: reads `../../volumes/jeromesiljan-com/nginx/logs` and pushes to Loki
- Retention: 30 days
