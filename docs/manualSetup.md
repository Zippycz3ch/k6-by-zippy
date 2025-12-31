`

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

   - Edit `.env` file in the root directory:
     - Set `BASEURL` (default: `http://quickpizza:3333`)
     - Set `PIZZA_TOKEN` (default: `abcdef0123456789`)
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
   docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js -e SCENARIO=100iter-10vu --tag testName=K6-API-getDoughs --tag project=quickPizza --tag testType=K6-API --tag release=dev --tag buildId=12345678
   ```

8. View live dashboards in Grafana
   All dashboards should now display live k6 results.

---
