Clear-Host

# Load environment configuration
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
}

$ENVIRONMENT = [Environment]::SetEnvironmentVariable('ENVIRONMENT', 'Process')
if ([string]::IsNullOrWhiteSpace($ENVIRONMENT)) {
    $ENVIRONMENT = "prod"
}

# Load config.json to get BASE URL for the environment
$configPath = Join-Path $PSScriptRoot "config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    $BASEURL = $config.environments.$ENVIRONMENT.baseUrl
    [Environment]::SetEnvironmentVariable('BASEURL', $BASEURL, 'Process')
    Write-Host "🌍 Environment: $ENVIRONMENT" -ForegroundColor Cyan
    Write-Host "🔗 Base URL: $BASEURL`n" -ForegroundColor Cyan
}
else {
    Write-Host "🌍 Environment: $ENVIRONMENT`n" -ForegroundColor Cyan
}

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

# 3. Load test data
if ($testTypeFolder -eq "API") {
    # Find all API test files
    $allTests = Get-ChildItem -Path $testTypeRoot -Recurse -Filter "*Test.js" | Select-Object -ExpandProperty FullName
    
    if ($allTests.Count -eq 0) {
        Write-Host "No API test files found in $testTypeRoot"
        exit 1
    }
    
    $allUrls = @()
    foreach ($testPath in $allTests) {
        $relativePath = $testPath.Replace("$testTypeRoot\\", "")
        $testName = [System.IO.Path]::GetFileNameWithoutExtension($testPath)
        $allUrls += [PSCustomObject]@{
            TestPath = "/tests/$testTypeFolder/" + $relativePath.Replace("\\", "/")
            TestName = $testName
            Category = Split-Path (Split-Path $testPath -Parent) -Leaf
        }
    }
}
else {
    # UI tests use data.json
    $dataFile = Join-Path $testTypeRoot "quickPizza\data.json"
    
    if (-not (Test-Path $dataFile)) {
        Write-Host "data.json not found: $dataFile"
        exit 1
    }
    
    $testData = Get-Content $dataFile | ConvertFrom-Json
    $allUrls = @()
    
    foreach ($urlEntry in $testData) {
        $allUrls += [PSCustomObject]@{
            Url      = $urlEntry.url
            TestName = $urlEntry.testName
        }
    }
}

Write-Host "`nFound $($allUrls.Count) URLs to test"

# 4. Ask for SCENARIO if API tests
if ($testTypeFolder -eq "API") {
    $scenarios = @(
        "1iter",
        "20iter-1vu",
        "20iter-5vu (default)",
        "20iter-10vu",
        "100iter-1vu",
        "100iter-5vu",
        "100iter-10vu"
    )
    $selectedScenario = Show-ChoicePrompt "Which scenario?" $scenarios
    $selectedScenario = $selectedScenario -replace " \(default\)", ""
}
else {
    # For UI tests, still use config files
    $configDir = Join-Path $testTypeRoot "configs"
    $configs = Get-ChildItem -Path $configDir -Filter *.json | Select-Object -ExpandProperty Name
    
    if (-not $configs) {
        Write-Host "No config files found in $configDir"
        exit 1
    }
    
    $selectedConfig = Show-ChoicePrompt "Which config file?" $configs
}

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

$release = Read-Host "Enter release name (e.g. v1.2.3 or sprint-45)"
if ([string]::IsNullOrWhiteSpace($release)) {
    $release = "dev"
}

$buildId = Read-Host 'Enter buildId (8 digit number or press Enter to generate)'
if ([string]::IsNullOrWhiteSpace($buildId)) {
    $buildId = Get-Random -Minimum 10000000 -Maximum 99999999
    Write-Host "Generated buildId: $buildId"
}

$confirm = Read-Host "Proceed? (Y/N or Enter for Y)"
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
    Write-Host "`nAPI tests will run with scenario: $selectedScenario`n" -ForegroundColor Cyan
}
else {
    Write-Host "`nUI tests will run with config: $selectedConfig`n" -ForegroundColor Cyan
}

foreach ($urlData in $urlsToTest) {
    $testid = "$project-$($urlData.TestName)"
    
    if ($testTypeFolder -eq "API") {
        Write-Host "`n[$counter/$($urlsToTest.Count)] Testing: $($urlData.TestName)"
        Write-Host "  Category: $($urlData.Category)"
        Write-Host "  TestName: $($urlData.TestName)"
        Write-Host "  Scenario: $selectedScenario"
        Write-Host "  testid: $testid"
        Write-Host "  release: $release"
        Write-Host "  buildId: $buildId"
        
        docker exec `
            -e ENVIRONMENT="$ENVIRONMENT" `
            -e SCENARIO="$selectedScenario" `
            k6 k6 run $($urlData.TestPath) `
            --tag testid=$testid `
            --tag project=$project `
            --tag testType=$testType `
            --tag testName=$($urlData.TestName) `
            --tag release=$release `
            --tag buildId=$buildId
    }
    else {
        Write-Host "`n[$counter/$($urlsToTest.Count)] Testing: $($urlData.Url)"
        Write-Host "  TestName: $($urlData.TestName)"
        Write-Host "  Config: $selectedConfig"
        Write-Host "  testid: $testid"
        Write-Host "  release: $release"
        Write-Host "  buildId: $buildId"
        
        $containerPath = "/tests/$testTypeFolder/uiTest.js"
        
        docker exec `
            -e ENVIRONMENT="$ENVIRONMENT" `
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
    }
    
    $exitCode = $LASTEXITCODE
    
    $results += [PSCustomObject]@{
        Url      = if ($testTypeFolder -eq "API") { "$($urlData.Method) $($urlData.Endpoint)" } else { $urlData.Url }
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
Write-Host ""
Write-Host "All tests complete."