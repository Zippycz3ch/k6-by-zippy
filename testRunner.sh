#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

show_choice_prompt() {
    local message="$1"
    shift
    local options=("$@")
    
    while true; do
        echo "$message" >&2
        for i in "${!options[@]}"; do
            echo "$((i+1)): ${options[$i]}" >&2
        done
        
        read -p "Enter number: " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice-1))]}"
            return 0
        else
            echo "Invalid selection. Please try again." >&2
            echo "" >&2
        fi
    done
}

# 1. Ask for test type first
echo "Test type:"
echo "1: UI Tests"
echo "2: API Tests"

read -p "Enter number (default: 1): " test_type_choice
test_type_choice=${test_type_choice:-1}

if [ "$test_type_choice" == "2" ]; then
    test_type_folder="API"
    test_type="K6-API"
else
    test_type_folder="UI"
    test_type="K6-UI"
fi

project="quickPizza"
echo -e "Selected test type: $test_type\n"

# 2. Find test root and files
repo_root="$(cd "$(dirname "$0")" && pwd)"
test_type_root="$repo_root/tests/$test_type_folder"

if [ ! -d "$test_type_root" ]; then
    echo "Test type folder not found: $test_type_root"
    exit 1
fi

if [ "$test_type_folder" == "API" ]; then
    test_file="$test_type_root/apiTest.ts"
    data_file="$test_type_root/quickPizza/data.json"
else
    test_file="$test_type_root/uiTest.js"
    data_file="$test_type_root/quickPizza/data.json"
fi

if [ ! -f "$test_file" ]; then
    echo "Test file not found: $test_file"
    exit 1
fi

if [ ! -f "$data_file" ]; then
    echo "data.json not found: $data_file"
    exit 1
fi

# 3. Load test data
echo -e "\nLoading test data from $data_file..."

# Parse JSON and extract URLs and testNames
mapfile -t urls < <(jq -r '.[].url' "$data_file")
mapfile -t test_names < <(jq -r '.[].testName' "$data_file")

echo -e "Found ${#urls[@]} URLs to test"

# 4. Ask for config scenario
config_dir="$test_type_root/configs"
mapfile -t configs < <(find "$config_dir" -name "*.json" -exec basename {} \;)

if [ ${#configs[@]} -eq 0 ]; then
    echo "No config files found in $config_dir"
    exit 1
fi

selected_config=$(show_choice_prompt "Which config file?" "${configs[@]}")

# 5. Ask for test range
echo -e "\nTest range options:"
echo "1: Test all ${#urls[@]} URLs"
echo "2: Test specific range"

read -p "Enter number (default: 1): " range_choice
range_choice=${range_choice:-1}

declare -a urls_to_test
declare -a test_names_to_test

if [ "$range_choice" == "2" ]; then
    read -p "Start index (1-${#urls[@]}): " start_idx
    read -p "End index (1-${#urls[@]}): " end_idx
    
    for ((i=$((start_idx-1)); i<$end_idx; i++)); do
        urls_to_test+=("${urls[$i]}")
        test_names_to_test+=("${test_names[$i]}")
    done
else
    urls_to_test=("${urls[@]}")
    test_names_to_test=("${test_names[@]}")
fi

echo -e "\nReady to run ${#urls_to_test[@]} test(s) with config $selected_config."

read -p "Enter release name (e.g., v1.2.3, sprint-45): " release
release=${release:-dev}

read -p "Enter buildId (8-digit number, press Enter to generate): " build_id
if [ -z "$build_id" ]; then
    build_id=$(shuf -i 10000000-99999999 -n 1)
    echo "Generated buildId: $build_id"
fi

read -p "Proceed? (Y/N, Enter = Y): " confirm
confirm=${confirm:-Y}

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# 6. Run k6 for each URL
declare -a exit_codes
counter=1
if [ "$test_type_folder" == "API" ]; then
    container_path="/tests/$test_type_folder/apiTest.ts"
else
    container_path="/tests/$test_type_folder/uiTest.js"
fi
scenario="${selected_config%.json}"

for i in "${!urls_to_test[@]}"; do
    url="${urls_to_test[$i]}"
    test_name="${test_names_to_test[$i]}"
    testid="$project-$test_name"
    
    echo -e "\n[$counter/${#urls_to_test[@]}] Testing: $url"
    echo "  TestName: $test_name"
    echo "  testid: $testid"
    echo "  release: $release"
    echo "  buildId: $build_id"
    
    docker exec \
        -e SCENARIO="$scenario" \
        -e url="$url" \
        -e testName="$test_name" \
        -e testType="$test_type_folder" \
        -e project="$project" \
        -it k6 k6 run "$container_path" \
        --tag testid="$testid" \
        --tag project="$project" \
        --tag testType="$test_type" \
        --tag testName="$test_name" \
        --tag release="$release" \
        --tag buildId="$build_id"
    
    exit_codes[$i]=$?
    
    ((counter++))
done

# 7. Show summary
echo -e "\n==== TEST SUMMARY ===="

failed_count=0
for i in "${!exit_codes[@]}"; do
    if [ "${exit_codes[$i]}" -ne 0 ]; then
        ((failed_count++))
    fi
done

if [ $failed_count -gt 0 ]; then
    echo -e "${RED}Some tests FAILED ($failed_count/${#urls_to_test[@]}):${NC}\n"
    for i in "${!exit_codes[@]}"; do
        if [ "${exit_codes[$i]}" -ne 0 ]; then
            echo -e "  ${RED}- [${test_names_to_test[$i]}] ${urls_to_test[$i]} | Exit: ${exit_codes[$i]}${NC}"
        fi
    done
else
    echo -e "${GREEN}All ${#urls_to_test[@]} tests passed!${NC}"
fi

echo "======================"
echo -e "\nAll tests complete."
