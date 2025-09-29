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

# 1. Ask for UI or API
$type = Show-ChoicePrompt "Which type of tests do you want to run?" @("UI", "API")

# 2. Ask for folder
if ($type -eq "UI") {
    $parent = "tests\UI"
}
else {
    $parent = "tests\API"
}

$folders = Get-ChildItem -Path $parent -Directory | Select-Object -ExpandProperty Name
if (-not $folders) {
    Write-Host "No folders found in $parent"
    exit 1
}
$selectedFolder = Show-ChoicePrompt "Which test folder?" $folders

# 3. Find test scripts in the selected folder
$testRoot = Join-Path $parent $selectedFolder
$testFiles = Get-ChildItem -Path $testRoot -Recurse -Filter *.js

if ($testFiles.Count -eq 0) {
    Write-Host "No test files found in $testRoot"
    exit 1
}

# 4. Ask for config scenario (find available configs in first test's config folder)
$configDir = Join-Path $testFiles[0].Directory.FullName "configs"
$configs = Get-ChildItem -Path $configDir -Filter *.json | Select-Object -ExpandProperty Name
if (-not $configs) {
    Write-Host "No config files found in $configDir"
    exit 1
}
$selectedConfig = Show-ChoicePrompt "Which config file?" $configs

# 5. Confirm
Write-Host "`nReady to run $($testFiles.Count) test(s) in $testRoot with config $selectedConfig."
$confirm = Read-Host "Proceed? (Y/N, Enter = Y)"
if (("" -eq $confirm) -or ($null -eq $confirm)) { $confirm = "Y" }
if ($confirm -notin @("Y", "y")) { Write-Host "Cancelled."; exit 0 }

# 6. Run each test file in Docker, add unique testid for Grafana/project filtering
$results = @()
foreach ($test in $testFiles) {
    $repoRoot = (Resolve-Path .).Path.TrimEnd('\', '/')
    $testPath = $test.FullName.Substring($repoRoot.Length).TrimStart('\', '/')
    $containerPath = "/$testPath" -replace "\\", "/"
    $containerPath = $containerPath -replace "/+", "/"

    $testName = [System.IO.Path]::GetFileNameWithoutExtension($test.FullName)
    $project = $selectedFolder
    $testid = "K6-$type-$testName"

    Write-Host "`nRunning: $containerPath"
    Write-Host "  testid: $testid"
    Write-Host "  project: $project"

    docker exec -e SCENARIO="$($selectedConfig -replace '.json$')" `
        -e testid="$testid" `
        -e project="$project" `
        -it k6 k6 run $containerPath --tag testid=$testid --tag project=$project

    $exitCode = $LASTEXITCODE

    $results += [PSCustomObject]@{
        Test     = $containerPath
        TestId   = $testid
        Project  = $project
        ExitCode = $exitCode
    }
}


Write-Host "`n==== TEST SUMMARY ===="
$failedTests = $results | Where-Object { $_.ExitCode -ne 0 }
if ($failedTests) {
    Write-Host "Some tests FAILED:`n"
    foreach ($fail in $failedTests) {
        Write-Host " - $($fail.Test) | testid: $($fail.TestId) | Exit: $($fail.ExitCode)"
    }
}
else {
    Write-Host "All tests passed."
}
Write-Host "======================"
Write-Host "`nAll tests complete."
