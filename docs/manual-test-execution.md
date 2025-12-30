## Manual Test Execution

### API Tests

API tests support ENV variable scenario selection:

- `1iter` - Single iteration, 1 VU
- `20iter-1vu`, `20iter-5vu`, `20iter-10vu` - 20 iterations with variable VUs
- `100iter-1vu`, `100iter-5vu`, `100iter-10vu` - 100 iterations with variable VUs

Default scenario: `20iter-5vu`

Run with Grafana tags (required for dashboards):

```sh
docker exec k6 k6 run /tests/API/apiSample.js \
  --tag testName=K6-API-sample \
  --tag project=quickPizza \
  --tag testType=K6-API \
  --tag release=dev \
  --tag buildId=12345678
```

Run API tests directly:

```sh
# Simple inline test
docker exec k6 k6 run /tests/API/apiSample.js --tag testName=K6-API-sample --tag project=quickPizza --tag testType=K6-API --tag release=dev --tag buildId=12345678

# Full test with scenario
docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js -e SCENARIO=100iter-10vu --tag testName=K6-API-getDoughs --tag project=quickPizza --tag testType=K6-API --tag release=dev --tag buildId=12345678
```

### UI Tests

UI tests support ENV variable scenario selection:

- `1iter` - Single iteration
- `20iter` - 20 iterations
- `100iter` - 100 iterations

Default scenario: `20iter`

Run UI tests with required tags:

```sh
# Simple test with default scenario
docker exec -it k6 k6 run /tests/UI/uiSample.ts --tag testName=K6-UI-uiSample --tag project=quickPizza --tag testType=K6-UI --tag release=dev --tag buildId=12345678

# With scenario selection
docker exec -it k6 k6 run /tests/UI/uiSample.ts -e SCENARIO=100iter --tag testName=K6-UI-uiSample --tag project=quickPizza --tag testType=K6-UI --tag release=dev --tag buildId=12345678
```

---
