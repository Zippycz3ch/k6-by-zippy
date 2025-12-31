## Troubleshooting

### Common Docker Commands

**Restart entire stack:**

```sh
cd docker
docker compose restart
```

**Restart individual service:**

```sh
docker compose restart influxdb
docker compose restart grafana
docker compose restart k6
docker compose restart quickpizza
```

**Stop and start stack:**

```sh
docker compose down
docker compose up -d
```

**View container status:**

```sh
docker compose ps
```

**View logs:**

```sh
docker logs influxdb
docker logs grafana
docker logs k6
docker logs quickpizza

# Follow logs in real-time
docker logs -f grafana
```

**Rebuild k6 image after changes:**

```sh
docker build -t custom-k6 .
docker compose up -d --force-recreate k6
```

### Common Issues

- Script not found:
  Make sure your test script path matches the volume mapping in `docker-compose.yml`.
- InfluxDB/Grafana errors:
  Check logs:
  ```sh
  docker logs influxdb
  docker logs grafana
  ```
- Custom k6 image not found:
  Always build the image first using the `docker build` command above.
- InfluxDB unauthorized errors:
  Ensure you're using the correct org, bucket, and token as described above.

---
