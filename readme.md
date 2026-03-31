# k6custom Performance Testing Stack

Complete local environment for API and UI performance testing using Grafana k6, InfluxDB v2.x and Grafana dashboards.

Tests run against local QuickPizza API instance included in Docker stack.

Change passwords for non-local deployments.

## Based on

- [k6](https://k6.io/)
- [Grafana](https://grafana.com/)
- [InfluxDB](https://www.influxdata.com/)
- [QuickPizza API]([https://github.com/k6io/quickpizza](https://github.com/grafana/quickpizza))

---

## Quick Automated Setup (Recommended)

Clone repository:

```sh
git clone https://github.com/Zippycz3ch/k6-by-zippy
cd k6-by-zippy
```

### Windows

```powershell
.\setup-k6custom.ps1
```

### Linux/Mac

```sh
chmod +x setup-k6custom.sh
./setup-k6custom.sh
```

### Setup Script Features

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

Interactive test runner for both API and UI tests.

#### Windows

```powershell
.\testRunner.ps1
```

#### Linux/Mac

```sh
chmod +x testRunner.sh
./testRunner.sh
```

#### Features

The runner allows selection of:

- Test type (API/UI)
- Specific test file
- Scenario configuration

### View Results

**Grafana Dashboards:** [http://localhost:3000](http://localhost:3000)

Additional services:

- InfluxDB: [http://localhost:8086](http://localhost:8086)
- QuickPizza API: [http://localhost:3333](http://localhost:3333)

---

## Additional Documentation

- [Manual Test Execution](docs/manual-test-execution.md)
- [Manual Setup Guide](docs/manual-setup.md)
- [Troubleshooting](docs/troubleshooting.md)

---
