# k6custom Performance Testing Stack

This repository provides a complete local environment for UI performance testing using Grafana k6, InfluxDB v2.x and Grafana dashboards.

Change your passwords if you use this as non local setup!

## Based on

- [k6](https://k6.io/)
- [Grafana](https://grafana.com/)
- [InfluxDB](https://www.influxdata.com/)
- [QuickPizza API](https://github.com/k6io/quickpizza)

---

## Quick Automated Setup (Recommended)

Use the provided PowerShell script for hassle-free setup and configuration.

Clone repository:

```sh
git clone https://github.com/Zippycz3ch/k6-by-zippy
cd k6-by-zippy
```

From the repo root, run:

```sh
./setup-k6custom.ps1
```

This script will:

- Check all required files and dashboards.
- Build custom k6 Docker image with browser support, InfluxDB output and faker.
- Start InfluxDB and guide you through onboarding.
- Start Grafana and guide you through onboarding and connectiong to Influx.
- Creates and updates Grafana dashboards with your InfluxDB token and updates other config files.
- Creates folder for screenshots from UI tests /screenshots
- Build and launch all containers.
- Run a sample test to verify the setup.

Default credentials

InfluxDB:

- Username: `k6user`
- Password: `k6password`
- Organization: `k6org`
- Bucket: `k6`

Grafana:

- Username: `admin`
- Password: `admin`

---

## Running Tests

After setup, you can run the UI data driven tests using the provided PowerShell script:

```sh
./testsRunner.ps1
```

Or you can run each test individually from the Docker folder. Update the tags to match with testRunner tags.

```sh
docker exec -it k6 k6 run /tests/UI/uiSample.js --tag testName=K6-UI-uiSample --tag project=uiSample --tag testType=K6-UI --tag release=dev --tag buildId=12345678
```

Open [http://localhost:3000](http://localhost:3000) (Grafana).

## Manual Setup

If you want to setup everything manually, start each container step by step as follows:

1. Start and initialize InfluxDB

   ```sh
   cd docker
   docker compose up -d InfluxDB
   ```

   Go to [http://localhost:8086](http://localhost:8086) and onboard using:

   - Username: `k6user`
   - Password: `k6password`
   - Organization: `k6org`
   - Bucket: `k6`
   - Copy the Admin Token.

2. Update config files

   - Edit `docker/Dockerfile`:
     - Set `K6_InfluxDB_TOKEN` to the above value.
   - Edit `docker/grafana/provisioning/datasources/InfluxDB.yml`:
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
         "type": "InfluxDB",
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
   docker exec -it k6 k6 run /tests/UI/uiSample.js --tag testName=K6-UI-uiSample --tag project=uiSample --tag testType=K6-UI --tag release=dev --tag buildId=12345678
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

---
