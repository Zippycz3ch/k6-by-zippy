Clear-Host

function Show-ChoicePrompt {
    param([string]$Message, [array]$Options)
    Write-Host $Message
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i+1): $($Options[$i])"
    }
    $choice = Read-Host "Enter number"
    if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $Options.Count) {
        return $Options[$choice - 1]
    }
    else {
        Write-Host "Invalid selection. Please try again.`n"
        return Show-ChoicePrompt $Message $Options
    }
}

# 1. Ask for test type first
Write-Host "Test type:"
Write-Host "1: UI Tests"
Write-Host "2: API Tests"

$testTypeChoice = Read-Host "Enter number (default: 1)"
if ([string]::IsNullOrWhiteSpace($testTypeChoice)) {
    $testTypeChoice = "1"
}

$testTypeFolder = if ($testTypeChoice -eq "2") { "API" } else { "UI" }
$testType = if ($testTypeChoice -eq "2") { "K6-API" } else { "K6-UI" }
$project = "quickPizza"
Write-Host "Selected test type: $testType`n"

# 2. Find test root and files
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$testTypeRoot = Join-Path $repoRoot "tests\$testTypeFolder"

if (-not (Test-Path $testTypeRoot)) {
    Write-Host "Test type folder not found: $testTypeRoot"
    exit 1
}

if ($testTypeFolder -eq "API") {
    $testFile = Join-Path $testTypeRoot "apiTest.ts"
    $dataFile = Join-Path $testTypeRoot "quickPizza\data.json"
} else {
    $testFile = Join-Path $testTypeRoot "uiTest.js"
    $dataFile = Join-Path $testTypeRoot "quickPizza\data.json"
}

if (-not (Test-Path $testFile)) {
    Write-Host "Test file not found: $testFile"
    exit 1
}

if (-not (Test-Path $dataFile)) {
    Write-Host "data.json not found: $dataFile"
    exit 1
}

# 3. Load test data
$testData = Get-Content $dataFile | ConvertFrom-Json
$allUrls = @()

foreach ($urlEntry in $testData) {
    $allUrls += [PSCustomObject]@{
        Url      = $urlEntry.url
        TestName = $urlEntry.testName
    }
}

Write-Host "`nFound $($allUrls.Count) URLs to test"

# 4. Ask for config scenario
$configDir = Join-Path $testTypeRoot "configs"
$configs = Get-ChildItem -Path $configDir -Filter *.json | Select-Object -ExpandProperty Name

if (-not $configs) {
    Write-Host "No config files found in $configDir"
    exit 1
}

$selectedConfig = Show-ChoicePrompt "Which config file?" $configs

# 5. Ask for test range
Write-Host "`nTest range options:"
Write-Host "1: Test all $($allUrls.Count) URLs"
Write-Host "2: Test specific range"

$rangeChoice = Read-Host "Enter number (default: 1)"
if ([string]::IsNullOrWhiteSpace($rangeChoice)) {
    $rangeChoice = "1"
}

$urlsToTest = @()
if ($rangeChoice -eq "2") {
    $startIdx = [int](Read-Host "Start index (1-$($allUrls.Count))")
    $endIdx = [int](Read-Host "End index (1-$($allUrls.Count))")
    $urlsToTest = $allUrls[($startIdx - 1)..($endIdx - 1)]
}
else {
    $urlsToTest = $allUrls
}

Write-Host "`nReady to run $($urlsToTest.Count) test(s) with config $selectedConfig."

$release = Read-Host "Enter release name (e.g., v1.2.3, sprint-45)"
if ([string]::IsNullOrWhiteSpace($release)) {
    $release = "dev"
}

$buildId = Read-Host "Enter buildId (8-digit number, press Enter to generate)"
if ([string]::IsNullOrWhiteSpace($buildId)) {
    $buildId = Get-Random -Minimum 10000000 -Maximum 99999999
    Write-Host "Generated buildId: $buildId"
}

$confirm = Read-Host "Proceed? (Y/N, Enter = Y)"
if ([string]::IsNullOrWhiteSpace($confirm)) {
    $confirm = "Y"
}

if ($confirm -notin @("Y", "y")) {
    Write-Host "Cancelled."
    exit 0
}

# 6. Run k6 for each URL
$results = @()
$counter = 1
if ($testTypeFolder -eq "API") {
    $containerPath = "/tests/$testTypeFolder/apiTest.ts"
} else {
    $containerPath = "/tests/$testTypeFolder/uiTest.js"
}

foreach ($urlData in $urlsToTest) {
    $testid = "$project-$($urlData.TestName)"
    
    Write-Host "`n[$counter/$($urlsToTest.Count)] Testing: $($urlData.Url)"
    Write-Host "  TestName: $($urlData.TestName)"
    Write-Host "  testid: $testid"
    Write-Host "  release: $release"
    Write-Host "  buildId: $buildId"
    
    docker exec `
        -e SCENARIO="$($selectedConfig -replace '.json$')" `
        -e url="$($urlData.Url)" `
        -e testName="$($urlData.TestName)" `
        -e testType="$testTypeFolder" `
        -e project="$project" `
        -it k6 k6 run $containerPath `
        --tag testid=$testid `
        --tag project=$project `
        --tag testType=$testType `
        --tag testName=$($urlData.TestName) `
        --tag release=$release `
        --tag buildId=$buildId
    
    $exitCode = $LASTEXITCODE
    
    $results += [PSCustomObject]@{
        Url      = $urlData.Url
        TestName = $urlData.TestName
        TestId   = $testid
        ExitCode = $exitCode
    }
    
    $counter++
}

Write-Host "`n==== TEST SUMMARY ===="
$failedTests = $results | Where-Object { $_.ExitCode -ne 0 }

if ($failedTests) {
    Write-Host "Some tests FAILED ($($failedTests.Count)/$($results.Count)):`n"
    foreach ($fail in $failedTests) {
        Write-Host "  - [$($fail.TestName)] $($fail.Url) | Exit: $($fail.ExitCode)"
    }
}
else {
    Write-Host "All $($results.Count) tests passed!"
}

Write-Host "======================"
Write-Host "`nAll tests complete."