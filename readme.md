# k6custom Performance Testing Stack

This repository provides a complete local environment for performance testing using Grafana k6, InfluxDB v2.x and Grafana dashboards/

---

## Running Tests

After setup, you can run the test suite using the provided PowerShell script:

```sh
./testsRunner.ps1
```

Or you can run each test individually from the Docker folder. Update the tags to match with testRunner tags.

```sh
docker exec -it k6 k6 run /tests/UI/hartmannb2c/produkty/produkty.js --tag testid=K6-UI-produkty --tag project=hartmannb2c
```
If you are runnign UI tests, folder screenshot will be created in root durring project setup. 

## Quick Automated Setup (Recommended)

Use the provided PowerShell script for hassle-free setup and configuration.

From the repo root, run:

```sh
./setup-k6custom.ps1
```


This script will:

- Check all required files and dashboards.
- Start InfluxDB and guide you through onboarding.
- Prompt you for the InfluxDB token.
- Update all needed config files and every dashboard JSON (including every occurrence of InfluxDB UID).
- Build and launch all containers.
- Guide you to connect Grafana and update dashboards.

Default credentials (for onboarding InfluxDB):

- Username: `k6user`
- Password: `k6password`
- Organization: `k6org`
- Bucket: `k6`

Grafana default login:

- Username: `admin`
- Password: `admin`

---

## Manual Setup (if you can't run the script)

1. Start and initialize InfluxDB

   ```sh
   cd docker
   docker compose up -d influxdb
   ```

   Go to [http://localhost:8086](http://localhost:8086) and onboard using:

   - Username: `k6user`
   - Password: `k6password`
   - Organization: `k6org`
   - Bucket: `k6`
   - Copy the Admin Token.

2. Update config files

   - Edit `docker/Dockerfile`:
     - Set `K6_INFLUXDB_TOKEN` to the above value.
   - Edit `docker/grafana/provisioning/datasources/influxdb.yml`:
     - Set the `organization:` and `token:` fields.

3. Build your custom k6 Docker image

   ```sh
   cd docker
   docker build -t custom-k6 .
   ```

4. Start the full stack

   ```sh
   cd docker
   docker compose up -d
   ```

5. Update all dashboards with correct InfluxDB UID

   - Open [http://localhost:3000](http://localhost:3000) (Grafana).
   - Log in:
     - Username: `admin`
     - Password: `admin`
   - Go to Connections → Data sources → InfluxDB.
   - Copy the UID from the browser URL (`/datasources/edit/<UID>`).
   - Find and replace the old UID in every `.json` file in `docker/grafana/dashboards/` (recursively):
     - Replace all occurrences of:
       ```json
       "datasource": {
         "type": "influxdb",
         "uid": "OLD-UID"
       }
       ```
       with your new UID.
   - Save all dashboard files.

6. Restart the stack

   ```sh
   cd docker
   docker compose down
   docker compose up -d
   ```

7. Run your k6 tests

   ```sh
   docker exec -it k6 k6 run /tests/UI/racom/homepage/homepage.js
   ```

8. View live dashboards in Grafana
   All dashboards should now display live k6 results.

---

## Troubleshooting

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
- To reset InfluxDB setup:
  Remove the `influxdb-data` docker volume and rerun onboarding if you want to start clean:
  ```sh
  docker compose down -v
  ```

---



## Credits

- [k6](https://k6.io/)
- [Grafana](https://grafana.com/)
- [QuickPizza API](https://github.com/k6io/quickpizza)

---
