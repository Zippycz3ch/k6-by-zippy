# k6custom Performance Testing Stack

Complete local environment for API and UI performance testing using Grafana k6, InfluxDB v2.x and Grafana dashboards.

Tests run against local QuickPizza API instance included in Docker stack.

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

**Windows:**

```powershell
.\setup-k6custom.ps1
```

**Linux/Mac:**

```sh
chmod +x setup-k6custom.sh
./setup-k6custom.sh
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

**Windows:**

```powershell
.\testRunner.ps1
```

**Linux/Mac:**

```sh
chmod +x testRunner.sh
./testRunner.sh
```

The runner allows selection of:

- Test type (API/UI)
- Specific test file
- Scenario configuration

### Manual Test Execution

#### API Tests

API tests support ENV variable scenario selection:

- `1iter` - Single iteration, 1 VU
- `20iter-1vu`, `20iter-5vu`, `20iter-10vu` - 20 iterations with variable VUs
- `100iter-1vu`, `100iter-5vu`, `100iter-10vu` - 100 iterations with variable VUs

Default scenario: `20iter-5vu`

Run with Grafana tags (required for dashboards):

```sh
docker exec k6 k6 run /tests/API/apiSample.js \
  --tag testid=K6-API-sample \
  --tag project=quickPizza \
  --tag testType=K6-API \
  --tag release=dev \
  --tag buildId=12345678
```

Run API tests directly:

```sh
# Simple inline test
docker exec k6 k6 run /tests/API/apiSample.js --tag testid=K6-API-sample --tag project=quickPizza --tag testType=K6-API --tag release=dev --tag buildId=12345678

# Full test with scenario
docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js -e SCENARIO=100iter-10vu --tag testid=K6-API-getDoughs --tag project=quickPizza --tag testType=K6-API --tag release=dev --tag buildId=12345678
```

#### UI Tests

UI tests support ENV variable scenario selection:

- `1iter` - Single iteration
- `20iter` - 20 iterations
- `100iter` - 100 iterations

Default scenario: `20iter`

Run UI tests with required tags:

```sh
# Simple test with default scenario
docker exec -it k6 k6 run /tests/UI/uiSample.ts --tag testid=K6-UI-uiSample --tag project=quickPizza --tag testType=K6-UI --tag release=dev --tag buildId=12345678

# With scenario selection
docker exec -it k6 k6 run /tests/UI/uiSample.ts -e SCENARIO=100iter --tag testid=K6-UI-uiSample --tag project=quickPizza --tag testType=K6-UI --tag release=dev --tag buildId=12345678
```

### View Results

**Grafana Dashboards:** [http://localhost:3000](http://localhost:3000)

Additional services:

- InfluxDB: [http://localhost:8086](http://localhost:8086)
- QuickPizza API: [http://localhost:3333](http://localhost:3333)

---

## Additional Documentation

- [Manual Setup Guide](docs/manual-setup.md)
- [Troubleshooting](docs/troubleshooting.md)

---
