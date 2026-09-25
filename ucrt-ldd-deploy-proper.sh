#!/usr/bin/env bash

set -euo pipefail

input=""
output="."
mingw_bin="${MINGW_PREFIX:-/ucrt64}/bin"
declare -a extra_dirs=()
declare -A visited=()

usage() {
    echo "Usage: $0 -i <executable> [-o <output>] [-u <mingw_bin>] [-s <search_dir>]"
    echo
    echo "  -i, --input       Input executable"
    echo "  -o, --output      Output directory (default: .)"
    echo "  -u, --ucrt-dir    MinGW/UCRT bin directory (default: \$MINGW_PREFIX/bin)"
    echo "  -s, --search-dir  Additional DLL search directory; may be specified multiple times"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)
            input="$2"
            shift 2
            ;;
        -o|--output)
            output="$2"
            shift 2
            ;;
        -u|--ucrt-dir)
            mingw_bin="$2"
            shift 2
            ;;
        -s|--search-dir)
            extra_dirs+=("$2")
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$input" ]]; then
    echo "Error: input executable is required."
    usage
fi

if [[ ! -f "$input" ]]; then
    echo "Error: file not found: $input"
    exit 1
fi

mkdir -p "$output"

input_dir="$(cd "$(dirname "$input")" && pwd)"
output="$(cd "$output" && pwd)"

is_system_dll() {
    local name="${1,,}"

    case "$name" in
        api-ms-win-*.dll|ext-ms-win-*.dll)
            return 0
            ;;
        kernel32.dll|kernelbase.dll|ntdll.dll)
            return 0
            ;;
        user32.dll|gdi32.dll|gdi32full.dll)
            return 0
            ;;
        advapi32.dll|sechost.dll|rpcrt4.dll)
            return 0
            ;;
        shell32.dll|shlwapi.dll|comdlg32.dll)
            return 0
            ;;
        ole32.dll|oleaut32.dll|combase.dll)
            return 0
            ;;
        ws2_32.dll|wsock32.dll|iphlpapi.dll)
            return 0
            ;;
        bcrypt.dll|crypt32.dll|cryptbase.dll)
            return 0
            ;;
        msvcrt.dll|ucrtbase.dll)
            return 0
            ;;
        setupapi.dll|cfgmgr32.dll|version.dll)
            return 0
            ;;
        winmm.dll|imm32.dll|dwmapi.dll)
            return 0
            ;;
        powrprof.dll|dbghelp.dll|psapi.dll)
            return 0
            ;;
        normaliz.dll|dnsapi.dll|nsi.dll)
            return 0
            ;;
    esac

    return 1
}

get_dependencies() {
    local file="$1"

    objdump -p "$file" 2>/dev/null |
        sed -n 's/^[[:space:]]*DLL Name:[[:space:]]*//p'
}

find_dll() {
    local name="$1"
    local dir=""
    local result=""

    local search_dirs=(
        "$input_dir"
        "$mingw_bin"
        "${extra_dirs[@]}"
    )

    for dir in "${search_dirs[@]}"; do
        [[ -d "$dir" ]] || continue

        result="$(find "$dir" -maxdepth 1 -type f -iname "$name" -print -quit 2>/dev/null)"

        if [[ -n "$result" ]]; then
            printf '%s\n' "$result"
            return 0
        fi
    done

    return 1
}

copy_dependency() {
    local name="$1"
    local lower="${name,,}"
    local src=""

    if is_system_dll "$name"; then
        return
    fi

    if [[ -n "${visited[$lower]:-}" ]]; then
        return
    fi

    visited["$lower"]=1

    if ! src="$(find_dll "$name")"; then
        echo "WARNING: Could not locate dependency: $name"
        return
    fi

    echo "$src -> $output/$name"
    cp -u "$src" "$output/$name"

    while IFS= read -r dependency; do
        [[ -n "$dependency" ]] || continue
        copy_dependency "$dependency"
    done < <(get_dependencies "$src")
}

echo "Input:  $input"
echo "Output: $output"
echo "MinGW:  $mingw_bin"
echo

while IFS= read -r dependency; do
    [[ -n "$dependency" ]] || continue
    copy_dependency "$dependency"
done < <(get_dependencies "$input")

echo
echo "Dependency collection complete."
echo "Copied ${#visited[@]} dependency names."