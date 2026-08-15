#!/bin/bash

# Parse arguments
input=""
output="."
ucrt_bin="${MINGW_PREFIX:-/ucrt64}/bin"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) input="$2"; shift ;;
        -o|--output) output="$2"; shift ;;
        -u|--ucrt-dir) ucrt_bin="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$input" ]]; then
    echo "Error: Input executable is required."
    echo "Usage: $0 -i <input> [-o <output>] [-u <ucrt_bin_dir>]"
    exit 1
fi

# Ensure the output directory exists
mkdir -p "$output"

# Function to copy a DLL to the output directory
copy_dll() {
    local input_loc="$1"

    # Ensure the line is a valid dependency mapping
    if [[ "$input_loc" != *"=>"* ]]; then
        return
    fi

    # Extract the DLL file name and the target path reported by ldd
    local fname=$(echo "$input_loc" | awk -F'=>' '{print $1}' | xargs)
    local raw_target=$(echo "$input_loc" | awk -F'=>' '{print $2}' | awk '{print $1}' | xargs)

    local src=""

    # Check if the DLL exists directly in the UCRT bin directory
    if [[ -f "$ucrt_bin/$fname" ]]; then
        src="$ucrt_bin/$fname"
    elif [[ -n "$raw_target" && -f "$raw_target" ]]; then
        src="$raw_target"
    elif [[ -n "$raw_target" ]]; then
        # Convert Windows style paths (C:\...) to MSYS2 POSIX paths (/c/...)
        local converted=$(cygpath -u "$raw_target" 2>/dev/null)
        if [[ -f "$converted" ]]; then
            src="$converted"
        fi
    fi

    # Only copy if the source exists and belongs to the UCRT environment
    if [[ -n "$src" && -f "$src" ]]; then
        cp -u "$src" "$output/$fname"
        if [[ $? -eq 0 ]]; then
            echo "$src -> $output/$fname"
        else
            echo "Failed to copy $src to $output/$fname"
            exit 1
        fi
    fi
}

# Extract DLL dependencies using ldd and filter out Windows system DLLs
extract_dll() {
    local input_file="$1"
    local output_dir="$2"

    echo "Extracting UCRT dependencies for $input_file -> $output_dir"

    ldd "$input_file" | grep -vi 'windows' | while IFS= read -r line; do
        copy_dll "$line"
    done
}

# Main script execution
extract_dll "$input" "$output"

