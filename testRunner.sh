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
        
        # Check if there's a default option
        local has_default=false
        for opt in "${options[@]}"; do
            if [[ "$opt" =~ \(default\) ]]; then
                has_default=true
                break
            fi
        done
        
        if [ "$has_default" = true ]; then
            read -p "Enter number (default: press Enter): " choice
        else
            read -p "Enter number: " choice
        fi
        
        # Check for empty input (default selection)
        if [ -z "$choice" ]; then
            # Find the option with (default) and return it
            for opt in "${options[@]}"; do
                if [[ "$opt" =~ \(default\) ]]; then
                    echo "$opt"
                    return 0
                fi
            done
            # If no default found, select first option
            echo "${options[0]}"
            return 0
        fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice-1))]}"
            return 0
        else
            echo "Invalid selection. Please try again." >&2
            echo "" >&2
        fi
    done
}

# 1. Ask for test type
test_types=("UI Tests (default)" "API Tests")
selected_type=$(show_choice_prompt "Test type:" "${test_types[@]}")

if [[ "$selected_type" =~ API ]]; then
    test_type_folder="API"
    test_type="K6-API"
else
    test_type_folder="UI"
    test_type="K6-UI"
fi

project="quickPizza"
echo -e "Selected: $test_type\n"


# 2. Find test root and files
repo_root="$(cd "$(dirname "$0")" && pwd)"
test_type_root="$repo_root/tests/$test_type_folder"

if [ ! -d "$test_type_root" ]; then
    echo "Test type folder not found: $test_type_root"
    exit 1
fi

# 3. Load test data
if [ "$test_type_folder" == "API" ]; then
    # Find all API test files
    mapfile -t test_files < <(find "$test_type_root" -name "*Test.js")
    
    if [ ${#test_files[@]} -eq 0 ]; then
        echo "No API test files found in $test_type_root"
        exit 1
    fi
    
    declare -a test_paths
    declare -a test_names
    declare -a test_categories
    
    for test_file in "${test_files[@]}"; do
        relative_path="${test_file#$test_type_root/}"
        test_name=$(basename "$test_file" .js)
        category=$(basename $(dirname "$test_file"))
        
        test_paths+=("${relative_path}")
        test_names+=("${test_name}")
        test_categories+=("${category}")
    done
else
    # UI tests use data.json
    data_file="$test_type_root/quickPizza/data.json"
    
    if [ ! -f "$data_file" ]; then
        echo "data.json not found: $data_file"
        exit 1
    fi
    
    # Parse JSON and extract paths and testNames
    mapfile -t paths < <(jq -r '.[].path' "$data_file")
    mapfile -t test_names < <(jq -r '.[].testName' "$data_file")
fi

# 4. Ask for SCENARIO
if [ "$test_type_folder" == "API" ]; then
    # API tests support more scenarios
    scenarios=(
        "1iter"
        "20iter-1vu"
        "20iter-5vu (default)"
        "20iter-10vu"
        "100iter-1vu"
        "100iter-5vu"
        "100iter-10vu"
        "breakpoint"
    )
    selected_scenario=$(show_choice_prompt "Which scenario?" "${scenarios[@]}")
    selected_scenario="${selected_scenario% (default)}"
    
    echo "Found ${#test_paths[@]} API test(s)"
else
    # UI scenarios
    scenarios=(
        "1iter-1vu"
        "20iter-1vu (default)"
        "10iter-1vu"
    )
    selected_scenario=$(show_choice_prompt "Which scenario?" "${scenarios[@]}")
    selected_scenario="${selected_scenario% (default)}"
    
    echo "Found ${#paths[@]} path(s) to test"
fi

# 5. Ask for test range
if [ "$test_type_folder" == "API" ]; then
    range_options=("Test all ${#test_names[@]} tests (default)" "Test specific range")
    range_choice=$(show_choice_prompt "Test range:" "${range_options[@]}")
    
    declare -a tests_to_run
    declare -a names_to_run
    declare -a categories_to_run
    
    if [[ "$range_choice" =~ specific ]]; then
        read -p "Start index (1-${#test_names[@]}): " start_idx
        read -p "End index (1-${#test_names[@]}): " end_idx
        
        for ((i=$((start_idx-1)); i<$end_idx; i++)); do
            tests_to_run+=("${test_paths[$i]}")
            names_to_run+=("${test_names[$i]}")
            categories_to_run+=("${test_categories[$i]}")
        done
    else
        tests_to_run=("${test_paths[@]}")
        names_to_run=("${test_names[@]}")
        categories_to_run=("${test_categories[@]}")
    fi
fi

if [ "$test_type_folder" == "UI" ]; then
    range_options=("Test all ${#paths[@]} paths (default)" "Test specific range")
    range_choice=$(show_choice_prompt "Test range:" "${range_options[@]}")
    
    declare -a paths_to_test
    declare -a test_names_to_test
    
    if [[ "$range_choice" =~ specific ]]; then
        read -p "Start index (1-${#paths[@]}): " start_idx
        read -p "End index (1-${#paths[@]}): " end_idx
        
        for ((i=$((start_idx-1)); i<$end_idx; i++)); do
            paths_to_test+=("${paths[$i]}")
            test_names_to_test+=("${test_names[$i]}")
        done
    else
        paths_to_test=("${paths[@]}")
        test_names_to_test=("${test_names[@]}")
    fi
fi

read -p "Enter release name (default: dev): " release
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

# Show what we're about to run
if [ "$test_type_folder" == "API" ]; then
    echo -e "\nReady to run ${#tests_to_run[@]} test(s) with scenario $selected_scenario."
else
    echo -e "\nReady to run ${#paths_to_test[@]} test(s) with scenario $selected_scenario."
fi

# 6. Run k6 for each test
declare -a exit_codes
counter=1

if [ "$test_type_folder" == "API" ]; then
    echo -e "\nRunning API tests with scenario: $selected_scenario\n"
    
    for i in "${!tests_to_run[@]}"; do
        test_path="${tests_to_run[$i]}"
        test_name="${names_to_run[$i]}"
        category="${categories_to_run[$i]}"
        testid="$project-$test_name"
        
        echo -e "\n[$counter/${#tests_to_run[@]}] Testing: $testid"
        echo "  Category: $category"
        echo "  TestName: $test_name"
        echo "  Scenario: $selected_scenario"
        echo "  release: $release"
        echo "  buildId: $build_id"
        
        docker exec \
            -e SCENARIO="$selected_scenario" \
            -it k6 k6 run "/tests/$test_type_folder/$test_path" \
            --tag testName="$test_name" \
            --tag testid="$testid" \
            --tag project="$project" \
            --tag testType="$test_type" \
            --tag release="$release" \
            --tag buildId="$build_id"
        
        exit_codes[$i]=$?
        ((counter++))
    done
else
    echo -e "\nRunning UI tests with scenario: $selected_scenario\n"
    
    for i in "${!paths_to_test[@]}"; do
        path="${paths_to_test[$i]}"
        test_name="${test_names_to_test[$i]}"
        testid="$project-$test_name"
        container_path="/tests/$test_type_folder/uiTest.js"
        
        echo -e "\n[$counter/${#paths_to_test[@]}] Testing: $test_name ($path)"
        echo "  TestName: $test_name"
        echo "  Scenario: $selected_scenario"
        echo "  release: $release"
        echo "  buildId: $build_id"
        
        docker exec \
            -e SCENARIO="$selected_scenario" \
            -e path="$path" \
            -e testName="$test_name" \
            -e testType="$test_type_folder" \
            -e project="$project" \
            -it k6 k6 run "$container_path" \
            --tag testName="$test_name" \
            --tag testid="$testid" \
            --tag project="$project" \
            --tag testType="$test_type" \
            --tag release="$release" \
            --tag buildId="$build_id"
        
        exit_codes[$i]=$?
        ((counter++))
    done
fi

# 7. Show summary
echo -e "\n==== TEST SUMMARY ===="

failed_count=0
if [ "$test_type_folder" == "API" ]; then
    total_count=${#tests_to_run[@]}
    for i in "${!exit_codes[@]}"; do
        if [ "${exit_codes[$i]}" -ne 0 ]; then
            ((failed_count++))
        fi
    done
    
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}Some tests FAILED ($failed_count/$total_count):${NC}\n"
        for i in "${!exit_codes[@]}"; do
            if [ "${exit_codes[$i]}" -ne 0 ]; then
                echo -e "  ${RED}- [${names_to_run[$i]}] ${categories_to_run[$i]} | Exit: ${exit_codes[$i]}${NC}"
            fi
        done
    else
        echo -e "${GREEN}All $total_count tests passed!${NC}"
    fi
else
    total_count=${#paths_to_test[@]}
    for i in "${!exit_codes[@]}"; do
        if [ "${exit_codes[$i]}" -ne 0 ]; then
            ((failed_count++))
        fi
    done
    
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}Some tests FAILED ($failed_count/$total_count):${NC}\n"
        for i in "${!exit_codes[@]}"; do
            if [ "${exit_codes[$i]}" -ne 0 ]; then
                echo -e "  ${RED}- [${test_names_to_test[$i]}] ${paths_to_test[$i]} | Exit: ${exit_codes[$i]}${NC}"
            fi
        done
    else
        echo -e "${GREEN}All $total_count tests passed!${NC}"
    fi
fi

echo "======================"
echo -e "\nAll tests complete."
