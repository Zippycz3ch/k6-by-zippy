# testRunner.ps1 - K6 Test Runner for API and UI Tests

Clear-Host

function Show-ChoicePrompt {
    param(
        [string]$Message,
        [array]$Options
    )
    
    while ($true) {
        Write-Host $Message
        for ($i = 0; $i -lt $Options.Length; $i++) {
            Write-Host "$($i + 1): $($Options[$i])"
        }
        
        # Check if there's a default option
        $hasDefault = $Options | Where-Object { $_ -match '\(default\)' }
        if ($hasDefault) {
            $choice = Read-Host "Enter number (default: press Enter)"
        }
        else {
            $choice = Read-Host "Enter number"
        }
        
        # Check for empty input (default selection)
        if ([string]::IsNullOrWhiteSpace($choice)) {
            # Find the option with (default) and return it
            $defaultOption = $Options | Where-Object { $_ -match '\(default\)' }
            if ($defaultOption) {
                return $defaultOption
            }
            # If no default found, select first option
            return $Options[0]
        }
        
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Length) {
            return $Options[[int]$choice - 1]
        }
        else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Write-Host ""
        }
    }
}

# 1. Ask for test type
Write-Host "Test type:"
Write-Host "1: UI Tests"
Write-Host "2: API Tests"

$testTypeChoice = Read-Host "Enter number (default: 1)"
if ([string]::IsNullOrWhiteSpace($testTypeChoice)) {
    $testTypeChoice = "1"
}

if ($testTypeChoice -eq "2") {
    $testTypeFolder = "API"
    $testType = "K6-API"
}
else {
    $testTypeFolder = "UI"
    $testType = "K6-UI"
}

$project = "quickPizza"
Write-Host "Selected test type: $testType"
Write-Host ""

# Read .env file for BASEURL
$envFile = Join-Path $PSScriptRoot ".env"
$baseUrlFromEnv = $null
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^BASEURL=(.+)$') {
            $baseUrlFromEnv = $matches[1].Trim()
        }
    }
}

# 2. Find test root and files
if ($PSScriptRoot) {
    $repoRoot = $PSScriptRoot
}
else {
    $repoRoot = (Get-Location).Path
}

$testTypeRoot = Join-Path $repoRoot "tests\$testTypeFolder"

if (-not (Test-Path $testTypeRoot)) {
    Write-Host "Test type folder not found: $testTypeRoot" -ForegroundColor Red
    exit 1
}

# 3. Load test data
if ($testTypeFolder -eq "API") {
    # Find all API test files
    $testFiles = Get-ChildItem -Path $testTypeRoot -Recurse -Filter "*Test.js"
    
    if ($testFiles.Count -eq 0) {
        Write-Host "No API test files found in $testTypeRoot" -ForegroundColor Red
        exit 1
    }
    
    $testPaths = @()
    $testNames = @()
    $testCategories = @()
    
    foreach ($testFile in $testFiles) {
        $relativePath = $testFile.FullName.Replace("$testTypeRoot\", "").Replace("\", "/")
        $testName = $testFile.BaseName
        $category = Split-Path -Leaf (Split-Path -Parent $testFile.FullName)
        
        $testPaths += $relativePath
        $testNames += $testName
        $testCategories += $category
    }
    
    Write-Host "Found $($testPaths.Count) API test(s)"
}
else {
    # UI tests use data.json
    $dataFile = Join-Path $testTypeRoot "quickPizza\data.json"
    
    if (-not (Test-Path $dataFile)) {
        Write-Host "data.json not found: $dataFile" -ForegroundColor Red
        exit 1
    }
    
    $dataContent = Get-Content $dataFile -Raw | ConvertFrom-Json
    $paths = $dataContent | ForEach-Object { $_.path }
    $testNames = $dataContent | ForEach-Object { $_.testName }
    
    Write-Host "Found $($paths.Count) path(s) to test"
}

# 4. Ask for SCENARIO
if ($testTypeFolder -eq "API") {
    # API tests support more scenarios
    $scenarios = @(
        "1iter",
        "20iter-1vu",
        "20iter-5vu (default)",
        "20iter-10vu",
        "100iter-1vu",
        "100iter-5vu",
        "100iter-10vu"
    )
    $selectedScenario = Show-ChoicePrompt -Message "Which scenario?" -Options $scenarios
    $selectedScenario = $selectedScenario -replace " \(default\)", ""
}
else {
    # UI scenarios
    $scenarios = @(
        "1iter-1vu",
        "20iter-1vu (default)",
        "10iter-1vu"
    )
    $selectedScenario = Show-ChoicePrompt -Message "Which scenario?" -Options $scenarios
    $selectedScenario = $selectedScenario -replace " \(default\)", ""
}

# 5. Ask for test range
if ($testTypeFolder -eq "API") {
    Write-Host ""
    Write-Host "Test range options:"
    Write-Host "1: Test all $($testNames.Count) tests"
    Write-Host "2: Test specific range"
    
    $rangeChoice = Read-Host "Enter number (default: 1)"
    if ([string]::IsNullOrWhiteSpace($rangeChoice)) {
        $rangeChoice = "1"
    }
    
    $testsToRun = @()
    $namesToRun = @()
    $categoriesToRun = @()
    
    if ($rangeChoice -eq "2") {
        $startIdx = Read-Host "Start index (1-$($testNames.Count))"
        $endIdx = Read-Host "End index (1-$($testNames.Count))"
        
        for ($i = [int]$startIdx - 1; $i -lt [int]$endIdx; $i++) {
            $testsToRun += $testPaths[$i]
            $namesToRun += $testNames[$i]
            $categoriesToRun += $testCategories[$i]
        }
    }
    else {
        $testsToRun = $testPaths
        $namesToRun = $testNames
        $categoriesToRun = $testCategories
    }
    
    Write-Host ""
    Write-Host "Ready to run $($testsToRun.Count) test(s) with scenario $selectedScenario."
}

if ($testTypeFolder -eq "UI") {
    Write-Host ""
    Write-Host "Test range options:"
    Write-Host "1: Test all $($paths.Count) paths"
    Write-Host "2: Test specific range"
    
    $rangeChoice = Read-Host "Enter number (default: 1)"
    if ([string]::IsNullOrWhiteSpace($rangeChoice)) {
        $rangeChoice = "1"
    }
    
    $pathsToTest = @()
    $testNamesToTest = @()
    
    if ($rangeChoice -eq "2") {
        $startIdx = Read-Host "Start index (1-$($paths.Count))"
        $endIdx = Read-Host "End index (1-$($paths.Count))"
        
        for ($i = [int]$startIdx - 1; $i -lt [int]$endIdx; $i++) {
            $pathsToTest += $paths[$i]
            $testNamesToTest += $testNames[$i]
        }
    }
    else {
        $pathsToTest = $paths
        $testNamesToTest = $testNames
    }
    
    Write-Host ""
    Write-Host "Ready to run $($pathsToTest.Count) test(s) with scenario $selectedScenario."
}

$release = Read-Host "Enter release name (e.g. v1.2.3 or sprint-45)"
if ([string]::IsNullOrWhiteSpace($release)) {
    $release = "dev"
}

$buildId = Read-Host "Enter buildId (8-digit number or press Enter to generate)"
if ([string]::IsNullOrWhiteSpace($buildId)) {
    $buildId = Get-Random -Minimum 10000000 -Maximum 99999999
    Write-Host "Generated buildId: $buildId"
}

$confirm = Read-Host "Proceed? (Y/N or Enter for Y)"
if ([string]::IsNullOrWhiteSpace($confirm)) {
    $confirm = "Y"
}

if ($confirm -notmatch '^[Yy]$') {
    Write-Host "Cancelled."
    exit 0
}

# 6. Run k6 for each test
$exitCodes = @()
$counter = 1

if ($testTypeFolder -eq "API") {
    Write-Host ""
    Write-Host "API tests will run with scenario: $selectedScenario"
    Write-Host ""
    
    for ($i = 0; $i -lt $testsToRun.Count; $i++) {
        $testPath = $testsToRun[$i]
        $testName = $namesToRun[$i]
        $category = $categoriesToRun[$i]
        $testid = "$project-$testName"
        
        Write-Host ""
        Write-Host "[$counter/$($testsToRun.Count)] Testing: $testid"
        Write-Host "  Category: $category"
        Write-Host "  TestName: $testName"
        Write-Host "  Scenario: $selectedScenario"
        Write-Host "  testName: $testName"
        Write-Host "  release: $release"
        Write-Host "  buildId: $buildId"
        
        docker exec `
            -e SCENARIO="$selectedScenario" `
            k6 k6 run "/tests/$testTypeFolder/$testPath" `
            --tag testName="$testName" `
            --tag testid="$testid" `
            --tag project="$project" `
            --tag testType="$testType" `
            --tag release="$release" `
            --tag buildId="$buildId"
        
        $exitCodes += $LASTEXITCODE
        $counter++
    }
}
else {
    Write-Host ""
    Write-Host "UI tests will run with scenario: $selectedScenario"
    Write-Host ""
    
    # Use BASEURL from .env file
    if ($baseUrlFromEnv) {
        $baseUrl = $baseUrlFromEnv
        Write-Host "Using BASEURL from .env: $baseUrl"
    }
    else {
        $baseUrl = Read-Host "Enter base URL (default: http://quickpizza:3333)"
        if ([string]::IsNullOrWhiteSpace($baseUrl)) {
            $baseUrl = "http://quickpizza:3333"
        }
    }
    Write-Host ""
    
    for ($i = 0; $i -lt $pathsToTest.Count; $i++) {
        $path = $pathsToTest[$i]
        $testName = $testNamesToTest[$i]
        $testid = "$project-$testName"
        $containerPath = "/tests/$testTypeFolder/uiTest.js"
        $fullUrl = "$baseUrl$path"
        
        Write-Host ""
        Write-Host "[$counter/$($pathsToTest.Count)] Testing: $fullUrl"
        Write-Host "  TestName: $testName"
        Write-Host "  Scenario: $selectedScenario"
        Write-Host "  testName: $testName"
        Write-Host "  release: $release"
        Write-Host "  buildId: $buildId"
        
        docker exec `
            -e SCENARIO="$selectedScenario" `
            -e BASEURL="$baseUrl" `
            -e path="$path" `
            -e testName="$testName" `
            -e testType="$testTypeFolder" `
            -e project="$project" `
            -it k6 k6 run "$containerPath" `
            --tag testName="$testName" `
            --tag testid="$testid" `
            --tag project="$project" `
            --tag testType="$testType" `
            --tag release="$release" `
            --tag buildId="$buildId"
        
        $exitCodes += $LASTEXITCODE
        $counter++
    }
}

# 7. Show summary
Write-Host ""
Write-Host "==== TEST SUMMARY ===="

$failedCount = 0
if ($testTypeFolder -eq "API") {
    $totalCount = $testsToRun.Count
    for ($i = 0; $i -lt $exitCodes.Count; $i++) {
        if ($exitCodes[$i] -ne 0) {
            $failedCount++
        }
    }
    
    if ($failedCount -gt 0) {
        Write-Host "Some tests FAILED ($failedCount/$totalCount):" -ForegroundColor Red
        Write-Host ""
        for ($i = 0; $i -lt $exitCodes.Count; $i++) {
            if ($exitCodes[$i] -ne 0) {
                Write-Host "  - [$($namesToRun[$i])] $($categoriesToRun[$i]) | Exit: $($exitCodes[$i])" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "All $totalCount tests passed!" -ForegroundColor Green
    }
}
else {
    $totalCount = $pathsToTest.Count
    for ($i = 0; $i -lt $exitCodes.Count; $i++) {
        if ($exitCodes[$i] -ne 0) {
            $failedCount++
        }
    }
    
    if ($failedCount -gt 0) {
        Write-Host "Some tests FAILED ($failedCount/$totalCount):" -ForegroundColor Red
        Write-Host ""
        for ($i = 0; $i -lt $exitCodes.Count; $i++) {
            if ($exitCodes[$i] -ne 0) {
                Write-Host "  - [$($testNamesToTest[$i])] $($pathsToTest[$i]) | Exit: $($exitCodes[$i])" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "All $totalCount tests passed!" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "======================"
Write-Host ""
Write-Host "All tests complete."
