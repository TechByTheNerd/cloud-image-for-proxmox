#!/bin/bash

# Default run mode
RUN_MODE="async"

# Function to format elapsed time
format_time() {
        local total_seconds=$1
        local days=$((total_seconds/86400))
        local hours=$((total_seconds/3600%24))
        local minutes=$((total_seconds/60%60))
        local seconds=$((total_seconds%60))
        printf "%d.%02d:%02d:%02d" $days $hours $minutes $seconds
}

# Process command-line arguments
while (( "$#" )); do
    case "$1" in
        --sync|--async)
            RUN_MODE="${1:2}"
            shift
            ;;
        --help)
            echo ""
            echo "Usage: $0 [--sync | --async]"
            echo ""
            echo "Run scripts in synchronous (sync) or asynchronous (async) mode. Default is async."
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo "Error: Invalid argument '$1'"
            echo ""
            echo "Run '$0 --help' for usage."
            echo ""
            exit 1
    esac
done

start_time=$(date)
SECONDS=0

echo "[*] Running all scripts (${RUN_MODE}) at ${start_time}..."

run_script() {
        local script_path=$1
        local dir=$(dirname "${script_path}")
        local file=$(basename "${script_path}")

        if [ -f "${script_path}" ]; then
                echo "[*] Running ${script_path}..."
                cd "${dir}" && ./"${file}" > out.log 2>&1 &
                pid=$!
                if [ "${RUN_MODE}" = "sync" ]; then
                        wait $pid
                else
                        pids+=($pid)
                fi
        else
                echo "[!] ${script_path} does not exist. Make a copy of the _rebuild-*-templates.sh file into ${script_path} and configure it for your needs."
        fi
}

pids=()
run_script "./almalinux/rebuild-almalinux-templates.sh"
run_script "./centos/rebuild-centos-templates.sh"
run_script "./debian/rebuild-debian-templates.sh"
run_script "./opensuse/rebuild-opensuse_templates.sh"
run_script "./rockylinux/rebuild-rockylinux-templates.sh"
run_script "./ubuntu/rebuild-ubuntu_templates.sh"

echo "[*] Waiting for all background processes to finish..."
for pid in ${pids[*]}; do
        wait $pid
done

end_time=$(date)
elapsed_time=$(format_time $SECONDS)

echo "[+] Done at ${end_time}. Total elapsed time: ${elapsed_time}."