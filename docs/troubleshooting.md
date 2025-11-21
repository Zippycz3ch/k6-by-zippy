## Troubleshooting

- Script not found:
  Make sure your test script path matches the volume mapping in `docker-compose.yml`.
- InfluxDB/Grafana errors:
  Check logs:
  ```sh
  docker logs InfluxDB
  docker logs grafana
  ```
- Custom k6 image not found:
  Always build the image first using the `docker build` command above.
- InfluxDB unauthorized errors:
  Ensure you're using the correct org, bucket, and token as described above.
- To reset InfluxDB setup:
  Remove the `InfluxDB-data` docker volume and rerun onboarding if you want to start clean:
  ```sh
  docker compose down -v
  ```

---
