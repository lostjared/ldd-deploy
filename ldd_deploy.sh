#!/bin/bash

# Parse arguments
input=""
output="."

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) input="$2"; shift ;;
        -o|--output) output="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$input" ]]; then
    echo "Error: Input executable is required."
    echo "Usage: $0 -i <input> [-o <output>]"
    exit 1
fi

# Ensure the output directory exists
mkdir -p "$output"

# Function to copy a DLL to the output directory
copy_dll() {
    local input_loc="$1"
    local pos=$(echo "$input_loc" | grep -o -b '=>' | head -n1 | cut -d: -f1)
    local fname=$(echo "${input_loc:0:pos}" | xargs)
    local right=${input_loc:((pos+3))}
    local loc=$(echo "$right" | grep -o '^[^ ]*' | xargs)

    # Copy file to the output directory
    cp "$loc" "$output/$fname"
    if [[ $? -eq 0 ]]; then
        echo "$loc -> $output/$fname"
    else
        echo "Failed to copy $loc to $output/$fname"
        exit 1
    fi
}

# Extract DLL dependencies using ldd and filter out Windows references
extract_dll() {
    local input_file="$1"
    local output_dir="$2"

    ldd "$input_file" | grep -vi windows | while IFS= read -r line; do
        copy_dll "$line"
    done
}

# Main script execution
extract_dll "$input" "$output"
