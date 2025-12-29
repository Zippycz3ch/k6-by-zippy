function Update-FileContent {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Search,
        [Parameter(Mandatory)]
        [string]$Replace
    )
    (Get-Content $Path) -replace $Search, $Replace | Set-Content $Path
}

function Update-FileUid {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$NewUid
    )
    # Regex to match all influxdb datasource blocks and replace UID everywhere
    $pattern = '"datasource":\s*\{\s*"type":\s*"influxdb",\s*"uid":\s*"(.*?)"\s*\}'
    $content = Get-Content $Path -Raw
    if ($content -match $pattern) {
        $newBlock = '"datasource": {
          "type": "influxdb",
          "uid": "' + $NewUid + '"
        }'
        $updated = [regex]::Replace($content, $pattern, $newBlock, "IgnoreCase, Multiline")
        Set-Content $Path $updated
        Write-Host "  - $Path updated." -ForegroundColor Green
    }
    else {
        Write-Host "  - No InfluxDB datasource block found in $Path." -ForegroundColor Yellow
    }
}

function Test-RequiredFile($Path, $Description) {
    if (-not (Test-Path $Path)) {
        Write-Host "`nERROR: $Description ('$Path') not found. Script will exit." -ForegroundColor Red
        exit 1
    }
}

function Read-RequiredInput($Prompt) {
    $val = ""
    while ([string]::IsNullOrWhiteSpace($val)) {
        $val = Read-Host $Prompt
    }
    return $val
}

Write-Host "`n==== k6custom Performance Testing Stack Setup ====" -ForegroundColor Cyan

# 1. Check required files/directories
Write-Host "`n[1/9] Checking for required files and directories..."

Test-RequiredFile "./docker/Dockerfile" "Dockerfile"
Test-RequiredFile "./docker/grafana/provisioning/datasources/influxdb.yml" "Grafana InfluxDB provisioning file"

$jsonPaths = Get-ChildItem -Path "./docker/grafana/dashboards" -Recurse -Filter *.json | Select-Object -ExpandProperty FullName

if ($jsonPaths.Count -eq 0) {
    Write-Host "`nERROR: No .json dashboard files found under ./docker/grafana/dashboards/. Script will exit." -ForegroundColor Red
    exit 1
}

Write-Host "  - Found Dockerfile at ./docker/Dockerfile"
Write-Host "  - Found Grafana InfluxDB provisioning at ./docker/grafana/provisioning/datasources/influxdb.yml"
Write-Host "  - Found $($jsonPaths.Count) .json dashboard file(s) under ./docker/grafana/dashboards/"

# 2. Start only InfluxDB container
Write-Host "`n[2/9] Starting InfluxDB container..." -ForegroundColor Yellow
Push-Location "./docker"
docker compose up -d influxdb
Pop-Location
Write-Host "InfluxDB container started." -ForegroundColor Green

# 3. Onboarding and collecting credentials
Write-Host "`n[3/9] Please complete onboarding in InfluxDB."
Write-Host "   For automated setup, use these default credentials:" -ForegroundColor Yellow
Write-Host "      Username:     k6user"      -ForegroundColor Yellow
Write-Host "      Password:     k6password"  -ForegroundColor Yellow
Write-Host "      Organization: k6org"       -ForegroundColor Yellow
Write-Host "      Bucket:       k6"          -ForegroundColor Yellow
Write-Host "   When the onboarding wizard finishes, it will show you the Admin Token."
Write-Host "   Copy the Admin Token and paste it below when ready."
$openInflux = Read-Host "Do you want to open InfluxDB UI in your browser now? [Y/N]"
if ($openInflux -eq "Y" -or $openInflux -eq "y" -or $openInflux -eq "") {
    Start-Process "http://localhost:8086"
    Write-Host "Browser opened for InfluxDB onboarding."
}
else {
    Write-Host "Please open http://localhost:8086 in your browser manually."
}
$token = Read-RequiredInput "Paste your InfluxDB Admin Token (required):"

Write-Host "`nNow, in the InfluxDB wizard, click `"Quick Start`" to finish onboarding."

# 4. Update Dockerfile and influxdb.yml
Write-Host "`n[4/9] Updating Dockerfile and influxdb.yml with your values..."

$dockerfilePath = "./docker/Dockerfile"
Update-FileContent -Path $dockerfilePath -Search "K6_INFLUXDB_TOKEN=.*?\\$" -Replace "K6_INFLUXDB_TOKEN=$token \"
Write-Host "  - Dockerfile updated." -ForegroundColor Green

$influxymlPath = "./docker/grafana/provisioning/datasources/influxdb.yml"
Update-FileContent -Path $influxymlPath -Search "(token:).*" -Replace "`$1 $token"
Write-Host "  - influxdb.yml updated." -ForegroundColor Green

# 5. Build k6 image
Write-Host "`n[5/9] Building your custom k6 Docker image..."
Push-Location "./docker"
docker build -t custom-k6 .
Pop-Location
Write-Host "Custom k6 image built." -ForegroundColor Green

# 6. Start the whole stack
Write-Host "`n[6/9] Starting the full stack (InfluxDB, Grafana, k6)..." -ForegroundColor Yellow
Push-Location "./docker"
docker compose up -d
Pop-Location
Write-Host "All containers started." -ForegroundColor Green

# 7. Grafana UID step (all dashboard .json)
Write-Host "`n[7/9] Grafana setup required: Data source UID fix" 
Write-Host "   - Grafana is now running at http://localhost:3000"       -ForegroundColor Yellow
Write-Host "   - Log in with username: admin / password: admin"         -ForegroundColor Yellow
Write-Host "   - Go to Connections > Data sources > InfluxDB."          -ForegroundColor Red
Write-Host "   - Copy the UID from the browser URL: /datasources/edit/<UID>"-ForegroundColor Red
$openGrafana = Read-Host "Do you want to open Grafana in your browser now? [Y/N]"
if ($openGrafana -eq "Y" -or $openGrafana -eq "y" -or $openGrafana -eq "") {
    Start-Process "http://localhost:3000"
    Write-Host "Browser opened for Grafana."
}
else {
    Write-Host "Please open http://localhost:3000 in your browser manually."
}
$uid = Read-RequiredInput "Paste the InfluxDB Data Source UID you see in the browser URL (required):"

foreach ($jsonPath in $jsonPaths) {
    Update-FileUid -Path $jsonPath -NewUid $uid
}

# 8. Restart all
Write-Host "`n[8/9] Restarting the stack to apply changes..."
Push-Location "./docker"
docker compose down
docker compose up -d
Pop-Location
Write-Host "Stack restarted." -ForegroundColor Green

# 9. Run sample tests
Write-Host "`n[9/9] Running sample tests to verify setup..." -ForegroundColor Yellow
Write-Host "   This will test the API and UI with default scenarios." -ForegroundColor Yellow
$runSample = Read-Host "Do you want to run the sample tests now? [Y/N]"
if ($runSample -eq "Y" -or $runSample -eq "y" -or $runSample -eq "") {
    Write-Host "`n--- Running API Sample Test (inline simple test) ---" -ForegroundColor Cyan
    docker exec k6 k6 run /tests/API/apiSample.js
    
    Write-Host "`n--- Running UI Sample Test (quickpizza.grafana.com) ---" -ForegroundColor Cyan
    docker exec -it k6 k6 run /tests/UI/uiSample.js `
        --tag testid=K6-UI-quickPizzaSample `
        --tag project=quickPizza `
        --tag testType=K6-UI `
        --tag release=setup `
        --tag buildId=00000000
    
    Write-Host "`nSample tests completed. Check Grafana dashboards to see the results." -ForegroundColor Green
    $openGrafana = Read-Host "Do you want to open Grafana in your browser now? [Y/N]"
    if ($openGrafana -eq "Y" -or $openGrafana -eq "y" -or $openGrafana -eq "") {
        Start-Process "http://localhost:3000/dashboards"
        Write-Host "Browser opened for Grafana."
    }
    else {
        Write-Host "Please open http://localhost:3000/dashboards in your browser manually."
    }
}
else {
    Write-Host "Skipped sample tests. You can run them later with:" -ForegroundColor Yellow
    Write-Host "  API Test:  docker exec k6 k6 run /tests/API/apiSample.js" -ForegroundColor Cyan
    Write-Host "  API Full:  docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js -e SCENARIO=100iter-5vu" -ForegroundColor Cyan
    Write-Host "  UI Test:   docker exec -it k6 k6 run /tests/UI/uiSample.js --tag testid=K6-UI-quickPizzaSample --tag project=quickPizza --tag testType=K6-UI --tag release=setup --tag buildId=00000000" -ForegroundColor Cyan
}

Write-Host "`n${GREEN}Setup Complete!${NC}" -ForegroundColor Green
Write-Host "API tests support ENV vars for scenarios: 1iter, 20iter-1vu, 20iter-5vu (default), 20iter-10vu, 100iter-1vu, 100iter-5vu, 100iter-10vu" -ForegroundColor Cyan
Write-Host "Example: docker exec k6 k6 run /tests/API/apiSample.js" -ForegroundColor Cyan
Write-Host "         docker exec k6 k6 run /tests/API/pizza/getDoughs/getDoughsTest.js -e SCENARIO=1iter" -ForegroundColor Cyan
