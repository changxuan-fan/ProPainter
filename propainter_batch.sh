#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -v <video_dir> -m <mask_dir>"
    exit 1
}

# Parse command line options using getopts
while getopts ":v:m:" opt; do
    case $opt in
        v) video_dir="$OPTARG" ;;
        m) mask_dir="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all required options are provided
if [ -z "$video_dir" ] || [ -z "$mask_dir" ]; then
    usage
fi

run_inference() {
    local VIDEO_DIR="$1"
    local MASK_DIR="$2"

    # Record the start time
    local start_time=$(date +%s)

    # Get the number of available GPUs
    local NUM_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)

    # Function to run a command on a specific GPU
    run_command() {
        local gpu_id=$1
        local sub_dir=$2
        local mask_sub_dir=$3
        local video_name=$4
        mkdir -p "results/$video_name"
        CUDA_VISIBLE_DEVICES=$gpu_id python inference_propainter.py --video "$sub_dir" --mask "$mask_sub_dir" --output "results/$video_name" --subvideo_length 100 --save_fps 30
    }

    # Initialize an array to track GPU availability
    declare -a gpu_available
    for ((i=0; i<NUM_GPUS; i++)); do
        gpu_available[i]=1
    done

    # Initialize an array to hold PIDs for background processes
    declare -a gpu_pids

    # Iterate over each video directory (video1, video2, etc.)
    for video_dir in "$VIDEO_DIR"/*; do
        [ -d "$video_dir" ] || continue
        video_name=$(basename "$video_dir")

        # Get the sorted list of numeric subdirectories within each video directory
        local sub_dirs=$(find "$video_dir" -maxdepth 1 -mindepth 1 -type d | grep -E '/[0-9]+$' | sort)

        # Process each subdirectory
        for sub_dir in $sub_dirs; do
            local sub_dir_name=$(basename "$sub_dir")
            local mask_sub_dir="$MASK_DIR/$video_name/$sub_dir_name"

            if [ -d "$mask_sub_dir" ]; then
                while : ; do
                    for ((i=0; i<NUM_GPUS; i++)); do
                        if [[ ${gpu_available[i]} -eq 1 ]]; then
                            gpu_available[i]=0
                            run_command $i "$sub_dir" "$mask_sub_dir" "$video_name" &
                            gpu_pids[i]=$!
                            break 2
                        fi
                    done
                    # Check if any GPU has finished its task
                    for ((i=0; i<NUM_GPUS; i++)); do
                        if [[ -n "${gpu_pids[i]}" && ! -e /proc/"${gpu_pids[i]}" ]]; then
                            gpu_available[i]=1
                        fi
                    done
                    sleep 1
                done
            else
                echo "Mask directory $mask_sub_dir does not exist."
            fi
        done
    done

    # Wait for all background processes to complete
    wait

    # Display the total execution time in a human-readable format
    local end_time=$(date +%s)
    local execution_time=$((end_time - start_time))
    local hours=$((execution_time / 3600))
    local minutes=$(( (execution_time % 3600) / 60 ))
    local seconds=$((execution_time % 60))
    echo "Total execution time: ${hours}h ${minutes}m ${seconds}s"
}

# Call the function with the provided directories
run_inference "$video_dir" "$mask_dir"
