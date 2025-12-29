# k6custom Performance Testing Stack

Complete local environment for API and UI performance testing using Grafana k6, InfluxDB v2.x and Grafana dashboards.

Change passwords for non-local deployments.

## Based on

- [k6](https://k6.io/)
- [Grafana](https://grafana.com/)
- [InfluxDB](https://www.influxdata.com/)
- [QuickPizza API](https://github.com/k6io/quickpizza)

---

## Quick Automated Setup (Recommended)

Clone repository:

```sh
git clone https://github.com/Zippycz3ch/k6-by-zippy
cd k6-by-zippy
```

Run from repo root:

```sh
./setup-k6custom.ps1
```

The script performs:

- Validates required files and dashboards
- Builds custom k6 Docker image with browser support, InfluxDB output and faker
- Starts and configures InfluxDB
- Starts and configures Grafana with InfluxDB connection
- Updates Grafana dashboards with InfluxDB token and configuration
- Creates screenshots directory for UI test outputs
- Launches all containers
- Runs sample tests to verify setup

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

### Test Runner (Recommended)

Interactive test runner for both API and UI tests:

```sh
./testRunner.ps1
```

The runner allows selection of:

- Test type (API/UI)
- Specific test file
- Scenario configuration (for API tests)

### API Tests

API tests support ENV variable scenario selection:

- `1iter` - Single iteration, 1 VU
- `20iter-1vu`, `20iter-5vu`, `20iter-10vu` - 20 iterations with variable VUs
- `100iter-1vu`, `100iter-5vu`, `100iter-10vu` - 100 iterations with variable VUs

Default scenario: `20iter-5vu`

Run API tests directly:

```sh
# Simple inline test
docker exec k6 k6 run /tests/API/apiSample.js

# Full test with scenario
docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js -e SCENARIO=100iter-10vu
```

### UI Tests

Run UI tests with required tags:

```sh
docker exec -it k6 k6 run /tests/UI/uiSample.ts --tag testid=K6-UI-uiSample --tag project=quickPizza --tag testType=K6-UI --tag release=dev --tag buildId=12345678
```

### View Results

Open [http://localhost:3000](http://localhost:3000) for Grafana dashboards.

## Manual Setup

Manual setup process:

1. Start and initialize InfluxDB

   ```sh
   cd docker
   docker compose up -d InfluxDB
   ```

   Navigate to [http://localhost:8086](http://localhost:8086) and configure:

   - Username: `k6user`
   - Password: `k6password`
   - Organization: `k6org`
   - Bucket: `k6`
   - Copy the Admin Token

2. Update config files

   - Edit `docker/Dockerfile`:
     - Set `K6_InfluxDB_TOKEN` to the token value
   - Edit `docker/grafana/provisioning/datasources/InfluxDB.yml`:
     - Set `organization:` and `token:` fields
   - Edit `docker/docker-compose.yml`:
     - Set `PIZZA_TOKEN` environment variable in k6 service

3. Build custom k6 Docker image

   ```sh
   cd docker
   docker build -t custom-k6 .
   ```

4. Start full stack

   ```sh
   cd docker
   docker compose up -d
   ```

5. Update dashboards with InfluxDB UID

   - Navigate to [http://localhost:3000](http://localhost:3000)
   - Login: admin/admin
   - Go to Connections → Data sources → InfluxDB
   - Copy UID from URL (`/datasources/edit/<UID>`)
   - Replace old UID in all `.json` files in `docker/grafana/dashboards/`:
     ```json
     "datasource": {
       "type": "InfluxDB",
       "uid": "OLD-UID"
     }
     ```
   - Save all dashboard files

6. Restart stack

   ```sh
   cd docker
   docker compose down
   docker compose up -d
   ```

7. Run tests

   ```sh
   docker exec k6 k6 run /tests/API/apiSample.js
   docker exec -it k6 k6 run /tests/UI/uiSample.ts --tag testid=K6-UI-uiSample --tag project=quickPizza --tag testType=K6-UI --tag release=dev --tag buildId=12345678
   ```

8. View dashboards in Grafana

---

## Troubleshooting

- **Script not found**: Verify test script path matches volume mapping in `docker-compose.yml`
- **InfluxDB/Grafana errors**: Check logs:
  ```sh
  docker logs InfluxDB
  docker logs grafana
  ```
- **Custom k6 image not found**: Build image using `docker build` command
- **InfluxDB unauthorized errors**: Verify correct org, bucket, and token configuration
- **Reset InfluxDB**: Remove docker volume and rerun onboarding:
  ```sh
  docker compose down -v
  ```

---
