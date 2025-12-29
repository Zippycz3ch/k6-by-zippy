#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

update_file_content() {
    local path="$1"
    local search="$2"
    local replace="$3"
    sed -i "s|${search}|${replace}|g" "$path"
}

update_file_uid() {
    local path="$1"
    local new_uid="$2"
    
    # Check if file contains influxdb datasource block
    if grep -q '"type":\s*"influxdb"' "$path"; then
        # Replace UID in datasource blocks using perl for better regex support
        perl -i -pe 's/"datasource":\s*\{\s*"type":\s*"influxdb",\s*"uid":\s*".*?"\s*\}/"datasource": {\n          "type": "influxdb",\n          "uid": "'"$new_uid"'"\n        }/gs' "$path"
        echo -e "  ${GREEN}- $path updated.${NC}"
    else
        echo -e "  ${YELLOW}- No InfluxDB datasource block found in $path.${NC}"
    fi
}

test_required_file() {
    local path="$1"
    local description="$2"
    
    if [ ! -f "$path" ] && [ ! -d "$path" ]; then
        echo -e "\n${RED}ERROR: $description ('$path') not found. Script will exit.${NC}"
        exit 1
    fi
}

read_required_input() {
    local prompt="$1"
    local value=""
    
    while [ -z "$value" ]; do
        read -p "$prompt " value
    done
    
    echo "$value"
}

echo -e "\n${CYAN}==== k6custom Performance Testing Stack Setup ====${NC}"

# 1. Check required files/directories
echo -e "\n[1/9] Checking for required files and directories..."

test_required_file "./docker/Dockerfile" "Dockerfile"
test_required_file "./docker/grafana/provisioning/datasources/influxdb.yml" "Grafana InfluxDB provisioning file"

# Find all JSON dashboard files
mapfile -t json_paths < <(find ./docker/grafana/dashboards -type f -name "*.json")

if [ ${#json_paths[@]} -eq 0 ]; then
    echo -e "\n${RED}ERROR: No .json dashboard files found under ./docker/grafana/dashboards/. Script will exit.${NC}"
    exit 1
fi

echo "  - Found Dockerfile at ./docker/Dockerfile"
echo "  - Found Grafana InfluxDB provisioning at ./docker/grafana/provisioning/datasources/influxdb.yml"
echo "  - Found ${#json_paths[@]} .json dashboard file(s) under ./docker/grafana/dashboards/"

# 2. Start only InfluxDB container
echo -e "\n${YELLOW}[2/9] Starting InfluxDB container...${NC}"
pushd ./docker > /dev/null
docker compose up -d influxdb
popd > /dev/null
echo -e "${GREEN}InfluxDB container started.${NC}"

# 3. Onboarding and collecting credentials
echo -e "\n[3/9] Please complete onboarding in InfluxDB."
echo -e "   ${YELLOW}For automated setup, use these default credentials:${NC}"
echo -e "      ${YELLOW}Username:     k6user${NC}"
echo -e "      ${YELLOW}Password:     k6password${NC}"
echo -e "      ${YELLOW}Organization: k6org${NC}"
echo -e "      ${YELLOW}Bucket:       k6${NC}"
echo "   When the onboarding wizard finishes, it will show you the Admin Token."
echo "   Copy the Admin Token and paste it below when ready."

read -p "Do you want to open InfluxDB UI in your browser now? [Y/N]: " open_influx
if [[ "$open_influx" =~ ^[Yy]$ ]] || [ -z "$open_influx" ]; then
    xdg-open "http://localhost:8086" 2>/dev/null || echo "Please open http://localhost:8086 in your browser manually."
    echo "Browser opened for InfluxDB onboarding."
else
    echo "Please open http://localhost:8086 in your browser manually."
fi

token=$(read_required_input "Paste your InfluxDB Admin Token (required):")

echo -e "\nNow, in the InfluxDB wizard, click \"Quick Start\" to finish onboarding."

# 4. Update Dockerfile and influxdb.yml
echo -e "\n[4/9] Updating Dockerfile and influxdb.yml with your values..."

dockerfile_path="./docker/Dockerfile"
update_file_content "$dockerfile_path" "K6_INFLUXDB_TOKEN=.*\\\\\$" "K6_INFLUXDB_TOKEN=$token \\\\"
echo -e "  ${GREEN}- Dockerfile updated.${NC}"

influxyml_path="./docker/grafana/provisioning/datasources/influxdb.yml"
sed -i "s/\(token:\).*/\1 $token/" "$influxyml_path"
echo -e "  ${GREEN}- influxdb.yml updated.${NC}"

# 5. Build k6 image
echo -e "\n[5/9] Building your custom k6 Docker image..."
pushd ./docker > /dev/null
if docker build -t custom-k6 .; then
    popd > /dev/null
    echo -e "${GREEN}Custom k6 image built.${NC}"
else
    popd > /dev/null
    echo -e "\n${RED}ERROR: Failed to build custom k6 image. Please check the error messages above.${NC}"
    exit 1
fi

# 6. Start the whole stack
echo -e "\n${YELLOW}[6/9] Starting the full stack (InfluxDB, Grafana, k6)...${NC}"
pushd ./docker > /dev/null
docker compose up -d
popd > /dev/null
echo -e "${GREEN}All containers started.${NC}"

# 7. Grafana UID step (all dashboard .json)
echo -e "\n[7/9] Grafana setup required: Data source UID fix"
echo -e "   ${YELLOW}- Grafana is now running at http://localhost:3000${NC}"
echo -e "   ${YELLOW}- Log in with username: admin / password: admin${NC}"
echo -e "   ${RED}- Go to Connections > Data sources > InfluxDB.${NC}"
echo -e "   ${RED}- Copy the UID from the browser URL: /datasources/edit/<UID>${NC}"

read -p "Do you want to open Grafana in your browser now? [Y/N]: " open_grafana
if [[ "$open_grafana" =~ ^[Yy]$ ]] || [ -z "$open_grafana" ]; then
    xdg-open "http://localhost:3000" 2>/dev/null || echo "Please open http://localhost:3000 in your browser manually."
    echo "Browser opened for Grafana."
else
    echo "Please open http://localhost:3000 in your browser manually."
fi

uid=$(read_required_input "Paste the InfluxDB Data Source UID you see in the browser URL (required):")

for json_path in "${json_paths[@]}"; do
    update_file_uid "$json_path" "$uid"
done

# 8. Restart all
echo -e "\n[8/9] Restarting the stack to apply changes..."
pushd ./docker > /dev/null
docker compose down
docker compose up -d
popd > /dev/null
echo -e "${GREEN}Stack restarted.${NC}"

# 9. Run sample tests
echo -e "\n[9/9] Running sample tests to verify setup..."
echo -e "   ${YELLOW}This will test the API and UI with default scenarios.${NC}"

read -p "Do you want to run the sample tests now? [Y/N]: " run_sample
if [[ "$run_sample" =~ ^[Yy]$ ]] || [ -z "$run_sample" ]; then
    echo -e "\n${CYAN}--- Running API Sample Test (getDoughsTest with default 20iter-5vu) ---${NC}"
    docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js
    
    echo -e "\n${CYAN}--- Running UI Sample Test (quickpizza.grafana.com) ---${NC}"
    docker exec -it k6 k6 run /tests/UI/uiSample.ts \
        --tag testid=K6-UI-quickPizzaSample \
        --tag project=quickPizza \
        --tag testType=K6-UI \
        --tag release=setup \
        --tag buildId=00000000
    
    echo -e "\n${GREEN}Sample tests completed. Check Grafana dashboards to see the results.${NC}"
    
    read -p "Do you want to open Grafana in your browser now? [Y/N]: " open_grafana_final
    if [[ "$open_grafana_final" =~ ^[Yy]$ ]] || [ -z "$open_grafana_final" ]; then
        xdg-open "http://localhost:3000/dashboards" 2>/dev/null || echo "Please open http://localhost:3000/dashboards in your browser manually."
        echo "Browser opened for Grafana."
    else
        echo "Please open http://localhost:3000/dashboards in your browser manually."
    fi
else
    echo -e "${YELLOW}Skipped sample tests. You can run them later with:${NC}"
    echo -e "${CYAN}  API Test:  docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js${NC}"
    echo -e "${CYAN}  With ENV:  docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js -e SCENARIO=100iter-5vu${NC}"
    echo -e "${CYAN}  UI Test:   docker exec -it k6 k6 run /tests/UI/uiSample.ts --tag testid=K6-UI-quickPizzaSample --tag project=quickPizza --tag testType=K6-UI --tag release=setup --tag buildId=00000000${NC}"
fi

echo -e "\n${GREEN}Setup Complete!${NC}"
echo -e "${CYAN}API tests support ENV vars for scenarios: 1iter, 20iter-1vu, 20iter-5vu (default), 20iter-10vu, 100iter-1vu, 100iter-5vu, 100iter-10vu${NC}"
echo -e "${CYAN}Example: docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js -e SCENARIO=1iter${NC}"
